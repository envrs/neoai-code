package com.neoaiSelfHosted.binary.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.util.messages.MessageBusConnection
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.statusbar.StatusBarProvider
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * User information service for managing user authentication and profile data
 */
@Service(Service.Level.APP)
class UserInfoService : LifecycleComponent {
    
    companion object {
        fun getInstance(): UserInfoService = service()
        
        private const val DEFAULT_UPDATE_INTERVAL = 60000L // 1 minute
        private const val REQUEST_TIMEOUT = 5000 // 5 seconds
        private const val USER_INFO_ENDPOINT = "/api/user/info"
        private const val AUTH_ENDPOINT = "/api/auth/verify"
    }
    
    data class UserInfo(
        val id: String,
        val username: String,
        val email: String,
        val displayName: String,
        val avatar: String? = null,
        val plan: String = "free",
        val isActive: Boolean = true,
        val lastLogin: Long = System.currentTimeMillis()
    )
    
    data class AuthToken(
        val token: String,
        val refreshToken: String? = null,
        val expiresAt: Long,
        val tokenType: String = "Bearer"
    )
    
    private val isInitialized = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)
    private val currentUser = AtomicReference<UserInfo?>(null)
    private val currentToken = AtomicReference<AuthToken?>(null)
    private val lastUpdateTime = AtomicLong(0)
    private val updateLoopStarted = AtomicBoolean(false)
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private val messageBusConnection: MessageBusConnection = ApplicationManager.getApplication().messageBus.connect()
    private val gson = Gson()
    
    private var updateInterval = DEFAULT_UPDATE_INTERVAL
    private var updateLoop: ScheduledFuture<*>? = null
    
    override fun initialize() {
        if (isInitialized.getAndSet(true)) return
        
        // Load stored authentication data
        loadStoredAuthData()
        
        // Setup message bus listeners
        setupMessageBusListeners()
    }
    
    override fun isHealthy(): Boolean {
        return currentUser.get() != null && isTokenValid()
    }
    
    override fun pause() {
        isPaused.set(true)
        stopUpdateLoop()
    }
    
    override fun resume() {
        isPaused.set(false)
        startUpdateLoop()
    }
    
    override fun shutdown() {
        isInitialized.set(false)
        stopUpdateLoop()
        messageBusConnection.disconnect()
        scheduler.shutdown()
    }
    
    /**
     * Start the user info update loop
     */
    fun startUpdateLoop() {
        if (updateLoopStarted.getAndSet(true) || isPaused.get()) return
        
        updateLoop = scheduler.scheduleWithFixedDelay({
            try {
                if (!isPaused.get()) {
                    updateUserInfo()
                }
            } catch (e: Exception) {
                println("Error in user info update loop: ${e.message}")
            }
        }, 0, updateInterval, TimeUnit.MILLISECONDS)
    }
    
    /**
     * Stop the user info update loop
     */
    private fun stopUpdateLoop() {
        updateLoop?.cancel(true)
        updateLoop = null
        updateLoopStarted.set(false)
    }
    
    /**
     * Update user information from server
     */
    private fun updateUserInfo() {
        val appSettings = AppSettingsState.instance
        val serverUrl = appSettings.cloud2Url
        
        if (serverUrl.isBlank() || !isTokenValid()) {
            currentUser.set(null)
            return
        }
        
        try {
            val userInfoUrl = if (serverUrl.endsWith("/")) {
                "${serverUrl}api/user/info"
            } else {
                "$serverUrl/api/user/info"
            }
            
            val url = URL(userInfoUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = REQUEST_TIMEOUT
            connection.readTimeout = REQUEST_TIMEOUT
            connection.setRequestProperty("Authorization", "Bearer ${getCurrentToken()}")
            connection.setRequestProperty("User-Agent", "Neoai-IntelliJ-Plugin")
            
            val responseCode = connection.responseCode
            
            when (responseCode) {
                in 200..299 -> {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    val userInfo = gson.fromJson(response, UserInfo::class.java)
                    currentUser.set(userInfo)
                    lastUpdateTime.set(System.currentTimeMillis())
                    
                    StatusBarProvider.getInstance().showSuccessMessage("User info updated")
                }
                401 -> {
                    // Token expired, try to refresh
                    refreshToken()
                }
                in 400..499 -> {
                    StatusBarProvider.getInstance().updateErrorStatus("User info request failed: HTTP $responseCode")
                }
                in 500..599 -> {
                    StatusBarProvider.getInstance().updateErrorStatus("Server error fetching user info: HTTP $responseCode")
                }
                else -> {
                    StatusBarProvider.getInstance().updateErrorStatus("Unexpected response: HTTP $responseCode")
                }
            }
            
        } catch (e: JsonSyntaxException) {
            StatusBarProvider.getInstance().updateErrorStatus("Invalid user info response format")
        } catch (e: Exception) {
            StatusBarProvider.getInstance().updateErrorStatus("Failed to update user info: ${e.message}")
        }
    }
    
    /**
     * Refresh authentication token
     */
    private fun refreshToken() {
        val token = currentToken.get() ?: return
        val refreshToken = token.refreshToken ?: return
        
        val appSettings = AppSettingsState.instance
        val serverUrl = appSettings.cloud2Url
        
        if (serverUrl.isBlank()) return
        
        try {
            val authUrl = if (serverUrl.endsWith("/")) {
                "${serverUrl}api/auth/refresh"
            } else {
                "$serverUrl/api/auth/refresh"
            }
            
            val url = URL(authUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = REQUEST_TIMEOUT
            connection.readTimeout = REQUEST_TIMEOUT
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("User-Agent", "Neoai-IntelliJ-Plugin")
            connection.doOutput = true
            
            val requestBody = gson.toJson(mapOf("refreshToken" to refreshToken))
            connection.outputStream.write(requestBody.toByteArray())
            
            val responseCode = connection.responseCode
            
            if (responseCode in 200..299) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val newToken = gson.fromJson(response, AuthToken::class.java)
                currentToken.set(newToken)
                
                // Store new token
                storeAuthData(newToken)
                
                StatusBarProvider.getInstance().showSuccessMessage("Token refreshed")
            } else {
                // Refresh failed, clear authentication
                clearAuthentication()
                StatusBarProvider.getInstance().updateErrorStatus("Token refresh failed")
            }
            
        } catch (e: Exception) {
            clearAuthentication()
            StatusBarProvider.getInstance().updateErrorStatus("Token refresh error: ${e.message}")
        }
    }
    
    /**
     * Check if current token is valid
     */
    private fun isTokenValid(): Boolean {
        val token = currentToken.get() ?: return false
        return System.currentTimeMillis() < token.expiresAt
    }
    
    /**
     * Get current authentication token
     */
    private fun getCurrentToken(): String? {
        return currentToken.get()?.token
    }
    
    /**
     * Load stored authentication data
     */
    private fun loadStoredAuthData() {
        // This would load from secure storage
        // For now, we'll use a placeholder implementation
        // In a real implementation, this would use IntelliJ's PasswordSafe or similar
    }
    
    /**
     * Store authentication data securely
     */
    private fun storeAuthData(token: AuthToken) {
        // This would store to secure storage
        // Placeholder implementation
    }
    
    /**
     * Clear authentication data
     */
    private fun clearAuthentication() {
        currentToken.set(null)
        currentUser.set(null)
        // Clear stored data
    }
    
    /**
     * Setup message bus listeners
     */
    private fun setupMessageBusListeners() {
        messageBusConnection.subscribe(AppSettingsState.TOPIC, object : AppSettingsState.ChangeListener {
            override fun settingsChanged() {
                // Clear authentication if server URL changed
                clearAuthentication()
            }
        })
    }
    
    /**
     * Get current user information
     */
    fun getCurrentUser(): UserInfo? = currentUser.get()
    
    /**
     * Get current authentication token
     */
    fun getCurrentAuthToken(): AuthToken? = currentToken.get()
    
    /**
     * Check if user is authenticated
     */
    fun isAuthenticated(): Boolean = currentUser.get() != null && isTokenValid()
    
    /**
     * Get last update time
     */
    fun getLastUpdateTime(): Long = lastUpdateTime.get()
    
    /**
     * Set update interval
     */
    fun setUpdateInterval(intervalMs: Long) {
        updateInterval = intervalMs.coerceAtLeast(30000) // Minimum 30 seconds
        
        // Restart update loop with new interval
        if (updateLoopStarted.get() && !isPaused.get()) {
            stopUpdateLoop()
            startUpdateLoop()
        }
    }
    
    /**
     * Force immediate user info update
     */
    fun forceUpdate() {
        if (!isPaused.get()) {
            updateUserInfo()
        }
    }
    
    /**
     * Authenticate user with token
     */
    fun authenticate(token: String, refreshToken: String? = null, expiresAt: Long) {
        val authToken = AuthToken(token, refreshToken, expiresAt)
        currentToken.set(authToken)
        storeAuthData(authToken)
        
        // Update user info immediately
        updateUserInfo()
    }
    
    /**
     * Logout user
     */
    fun logout() {
        clearAuthentication()
        StatusBarProvider.getInstance().showSuccessMessage("Logged out")
    }
}
