package com.neoaiSelfHosted.binary.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.statusbar.StatusBarProvider
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.net.HttpURLConnection
import java.net.URL

/**
 * Health checker service for monitoring Neoai Self-Hosted connectivity
 */
@Service(Service.Level.APP)
class HealthChecker : LifecycleComponent {
    
    companion object {
        fun getInstance(): HealthChecker = service()
        
        private const val DEFAULT_HEALTH_CHECK_INTERVAL = 30000L // 30 seconds
        private const val DEFAULT_TIMEOUT = 5000 // 5 seconds
        private const val HEALTH_ENDPOINT = "/health"
    }
    
    private val isInitialized = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)
    private val lastHealthCheckTime = AtomicLong(0)
    private val isHealthy = AtomicBoolean(false)
    private var healthCheckInterval = DEFAULT_HEALTH_CHECK_INTERVAL
    
    override fun initialize() {
        if (isInitialized.getAndSet(true)) return
        
        // Update health status immediately
        performHealthCheck()
    }
    
    override fun isHealthy(): Boolean {
        // Perform health check if it's been too long since last check
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastHealthCheckTime.get() > healthCheckInterval) {
            performHealthCheck()
        }
        
        return isHealthy.get()
    }
    
    override fun pause() {
        isPaused.set(true)
    }
    
    override fun resume() {
        isPaused.set(false)
        performHealthCheck()
    }
    
    override fun shutdown() {
        isInitialized.set(false)
        isPaused.set(false)
    }
    
    /**
     * Perform health check against the configured server
     */
    private fun performHealthCheck() {
        if (isPaused.get()) return
        
        val appSettings = AppSettingsState.instance
        val serverUrl = appSettings.cloud2Url
        
        if (serverUrl.isBlank()) {
            isHealthy.set(false)
            return
        }
        
        try {
            val healthUrl = if (serverUrl.endsWith("/")) {
                "${serverUrl}health"
            } else {
                "$serverUrl/health"
            }
            
            val url = URL(healthUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = DEFAULT_TIMEOUT
            connection.readTimeout = DEFAULT_TIMEOUT
            connection.setRequestProperty("User-Agent", "Neoai-IntelliJ-Plugin")
            
            val responseCode = connection.responseCode
            isHealthy.set(responseCode in 200..299)
            
            if (isHealthy.get()) {
                StatusBarProvider.getInstance().updateConnectionStatus(true, serverUrl)
            } else {
                StatusBarProvider.getInstance().updateErrorStatus("Health check failed: HTTP $responseCode")
            }
            
        } catch (e: Exception) {
            isHealthy.set(false)
            StatusBarProvider.getInstance().updateErrorStatus("Health check failed: ${e.message}")
        } finally {
            lastHealthCheckTime.set(System.currentTimeMillis())
        }
    }
    
    /**
     * Force immediate health check
     */
    fun forceHealthCheck() {
        performHealthCheck()
    }
    
    /**
     * Get last health check timestamp
     */
    fun getLastHealthCheckTime(): Long = lastHealthCheckTime.get()
    
    /**
     * Set health check interval
     */
    fun setHealthCheckInterval(intervalMs: Long) {
        healthCheckInterval = intervalMs.coerceAtLeast(5000) // Minimum 5 seconds
    }
    
    /**
     * Get current health status
     */
    fun getCurrentHealthStatus(): Boolean = isHealthy.get()
    
    /**
     * Get detailed health information
     */
    fun getHealthInfo(): HealthInfo {
        return HealthInfo(
            isHealthy = isHealthy.get(),
            lastCheckTime = lastHealthCheckTime.get(),
            serverUrl = AppSettingsState.instance.cloud2Url,
            checkInterval = healthCheckInterval,
            isPaused = isPaused.get()
        )
    }
    
    /**
     * Health information data class
     */
    data class HealthInfo(
        val isHealthy: Boolean,
        val lastCheckTime: Long,
        val serverUrl: String,
        val checkInterval: Long,
        val isPaused: Boolean
    )
}
