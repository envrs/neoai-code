package com.neoaiSelfHosted.binary.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.util.messages.MessageBusConnection
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.statusbar.StatusBarProvider
import com.neoaiSelfHosted.notifications.ConnectionLostNotificationHandler
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * Connection monitor service for tracking Neoai Self-Hosted server connectivity
 */
@Service(Service.Level.APP)
class ConnectionMonitor : LifecycleComponent {
    
    companion object {
        fun getInstance(): ConnectionMonitor = service()
        
        private const val DEFAULT_CHECK_INTERVAL = 15000L // 15 seconds
        private const val CONNECTION_TIMEOUT = 3000 // 3 seconds
        private const val MAX_FAILURES = 3
    }
    
    enum class ConnectionStatus {
        CONNECTED,
        DISCONNECTED,
        CONNECTING,
        UNKNOWN
    }
    
    private val isInitialized = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)
    private val currentStatus = AtomicReference(ConnectionStatus.UNKNOWN)
    private val lastCheckTime = AtomicLong(0)
    private val consecutiveFailures = AtomicLong(0)
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private val messageBusConnection: MessageBusConnection = ApplicationManager.getApplication().messageBus.connect()
    
    private var checkInterval = DEFAULT_CHECK_INTERVAL
    private var connectionLostHandler: ConnectionLostNotificationHandler? = null
    
    override fun initialize() {
        if (isInitialized.getAndSet(true)) return
        
        // Initialize connection lost handler
        connectionLostHandler = ConnectionLostNotificationHandler()
        
        // Start monitoring
        startMonitoring()
        
        // Setup message bus listeners
        setupMessageBusListeners()
    }
    
    override fun isHealthy(): Boolean {
        return currentStatus.get() == ConnectionStatus.CONNECTED
    }
    
    override fun pause() {
        isPaused.set(true)
        stopMonitoring()
    }
    
    override fun resume() {
        isPaused.set(false)
        startMonitoring()
    }
    
    override fun shutdown() {
        isInitialized.set(false)
        stopMonitoring()
        messageBusConnection.disconnect()
    }
    
    /**
     * Start connection monitoring
     */
    private fun startMonitoring() {
        if (isPaused.get()) return
        
        scheduler.scheduleWithFixedDelay({
            if (!isPaused.get()) {
                checkConnection()
            }
        }, 0, checkInterval, TimeUnit.MILLISECONDS)
    }
    
    /**
     * Stop connection monitoring
     */
    private fun stopMonitoring() {
        scheduler.shutdown()
        try {
            if (!scheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                scheduler.shutdownNow()
            }
        } catch (e: InterruptedException) {
            scheduler.shutdownNow()
        }
    }
    
    /**
     * Check connection to the server
     */
    private fun checkConnection() {
        val appSettings = AppSettingsState.instance
        val serverUrl = appSettings.cloud2Url
        
        if (serverUrl.isBlank()) {
            updateConnectionStatus(ConnectionStatus.DISCONNECTED, "No server URL configured")
            return
        }
        
        try {
            updateConnectionStatus(ConnectionStatus.CONNECTING, "Checking connection...")
            
            val testUrl = if (serverUrl.endsWith("/")) {
                "${serverUrl}api/ping"
            } else {
                "$serverUrl/api/ping"
            }
            
            val url = URL(testUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = CONNECTION_TIMEOUT
            connection.readTimeout = CONNECTION_TIMEOUT
            connection.setRequestProperty("User-Agent", "Neoai-IntelliJ-Plugin")
            
            val responseCode = connection.responseCode
            
            when {
                responseCode in 200..299 -> {
                    updateConnectionStatus(ConnectionStatus.CONNECTED, "Connected to $serverUrl")
                    consecutiveFailures.set(0)
                }
                responseCode in 400..499 -> {
                    updateConnectionStatus(ConnectionStatus.DISCONNECTED, "Client error: HTTP $responseCode")
                    consecutiveFailures.incrementAndGet()
                }
                responseCode in 500..599 -> {
                    updateConnectionStatus(ConnectionStatus.DISCONNECTED, "Server error: HTTP $responseCode")
                    consecutiveFailures.incrementAndGet()
                }
                else -> {
                    updateConnectionStatus(ConnectionStatus.DISCONNECTED, "Unexpected response: HTTP $responseCode")
                    consecutiveFailures.incrementAndGet()
                }
            }
            
        } catch (e: Exception) {
            updateConnectionStatus(ConnectionStatus.DISCONNECTED, "Connection failed: ${e.message}")
            consecutiveFailures.incrementAndGet()
        } finally {
            lastCheckTime.set(System.currentTimeMillis())
        }
    }
    
    /**
     * Update connection status
     */
    private fun updateConnectionStatus(status: ConnectionStatus, message: String) {
        val oldStatus = currentStatus.getAndSet(status)
        
        if (oldStatus != status) {
            onConnectionStatusChanged(oldStatus, status, message)
        }
    }
    
    /**
     * Handle connection status changes
     */
    private fun onConnectionStatusChanged(oldStatus: ConnectionStatus, newStatus: ConnectionStatus, message: String) {
        when (newStatus) {
            ConnectionStatus.CONNECTED -> {
                StatusBarProvider.getInstance().updateConnectionStatus(true, AppSettingsState.instance.cloud2Url)
                StatusBarProvider.getInstance().showSuccessMessage("Connection restored")
            }
            ConnectionStatus.DISCONNECTED -> {
                StatusBarProvider.getInstance().updateConnectionStatus(false)
                
                // Show connection lost notification after consecutive failures
                if (consecutiveFailures.get() >= MAX_FAILURES) {
                    connectionLostHandler?.showConnectionLostNotification()
                }
            }
            ConnectionStatus.CONNECTING -> {
                StatusBarProvider.getInstance().updateLoadingStatus("Connecting...")
            }
            ConnectionStatus.UNKNOWN -> {
                StatusBarProvider.getInstance().updateErrorStatus("Connection status unknown")
            }
        }
    }
    
    /**
     * Setup message bus listeners
     */
    private fun setupMessageBusListeners() {
        messageBusConnection.subscribe(AppSettingsState.TOPIC, object : AppSettingsState.ChangeListener {
            override fun settingsChanged() {
                // Force reconnection check when settings change
                if (isInitialized.get() && !isPaused.get()) {
                    consecutiveFailures.set(0)
                    checkConnection()
                }
            }
        })
    }
    
    /**
     * Get current connection status
     */
    fun getConnectionStatus(): ConnectionStatus = currentStatus.get()
    
    /**
     * Get last check timestamp
     */
    fun getLastCheckTime(): Long = lastCheckTime.get()
    
    /**
     * Get consecutive failures count
     */
    fun getConsecutiveFailures(): Long = consecutiveFailures.get()
    
    /**
     * Force immediate connection check
     */
    fun forceConnectionCheck() {
        if (!isPaused.get()) {
            checkConnection()
        }
    }
    
    /**
     * Set connection check interval
     */
    fun setCheckInterval(intervalMs: Long) {
        checkInterval = intervalMs.coerceAtLeast(5000) // Minimum 5 seconds
        
        // Restart monitoring with new interval
        if (!isPaused.get()) {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    /**
     * Get detailed connection information
     */
    fun getConnectionInfo(): ConnectionInfo {
        return ConnectionInfo(
            status = currentStatus.get(),
            lastCheckTime = lastCheckTime.get(),
            consecutiveFailures = consecutiveFailures.get(),
            serverUrl = AppSettingsState.instance.cloud2Url,
            checkInterval = checkInterval,
            isPaused = isPaused.get()
        )
    }
    
    /**
     * Connection information data class
     */
    data class ConnectionInfo(
        val status: ConnectionStatus,
        val lastCheckTime: Long,
        val consecutiveFailures: Long,
        val serverUrl: String,
        val checkInterval: Long,
        val isPaused: Boolean
    )
}
