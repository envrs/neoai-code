package com.neoaiSelfHosted.binary.requests.userInfo

import com.google.gson.Gson
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.diagnostic.thisLogger
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.progress.ProgressManager
import com.intellij.openapi.progress.Task
import com.intellij.openapi.project.Project
import com.intellij.util.messages.Topic
import com.neoaiSelfHosted.binary.http.HttpClientFactory
import com.neoaiSelfHosted.settings.NeoaiSelfHostedSettings
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Service for managing user information and authentication
 */
@Service
class UserInfoService {
    private val logger = thisLogger()
    private val isRunning = AtomicBoolean(false)
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "UserInfoService").apply {
            isDaemon = true
        }
    }
    
    private val currentUserInfo = AtomicReference<UserInfoResponse?>(null)
    private val lastUpdateTime = AtomicReference<Long>(0L)
    private val updateInterval = TimeUnit.MINUTES.toMillis(30) // 30 minutes
    
    /**
     * Topic for user info change notifications
     */
    interface UserInfoListener {
        fun onUserInfoChanged(userInfo: UserInfoResponse?)
        fun onUserInfoError(error: String)
    }
    
    companion object {
        val USER_INFO_TOPIC = Topic("UserInfo", UserInfoListener::class.java)
        
        @JvmStatic
        fun getInstance(): UserInfoService {
            return ApplicationManager.getApplication().getService(UserInfoService::class.java)
        }
    }
    
    /**
     * Start the user info update loop
     */
    fun startUpdateLoop() {
        if (isRunning.compareAndSet(false, true)) {
            logger.info("Starting user info update loop")
            
            scheduler.scheduleAtFixedRate({
                try {
                    updateUserInfo()
                } catch (e: Exception) {
                    logger.error("Error in user info update loop: ${e.message}")
                }
            }, 0, updateInterval, TimeUnit.MILLISECONDS)
        }
    }
    
    /**
     * Stop the user info update loop
     */
    fun stopUpdateLoop() {
        if (isRunning.compareAndSet(true, false)) {
            logger.info("Stopping user info update loop")
            scheduler.shutdown()
        }
    }
    
    /**
     * Force an immediate update of user information
     */
    fun refreshUserInfo() {
        ProgressManager.getInstance().run(object : Task.Backgroundable(null, "Refreshing User Info", true) {
            override fun run(indicator: ProgressIndicator) {
                indicator.text = "Fetching user information..."
                updateUserInfo()
            }
        })
    }
    
    /**
     * Get the current user information
     */
    fun getCurrentUserInfo(): UserInfoResponse? {
        return currentUserInfo.get()
    }
    
    /**
     * Get the last update time
     */
    fun getLastUpdateTime(): Long {
        return lastUpdateTime.get()
    }
    
    /**
     * Check if user info is available and recent
     */
    fun isUserInfoFresh(): Boolean {
        val lastUpdate = lastUpdateTime.get()
        return lastUpdate > 0 && (System.currentTimeMillis() - lastUpdate) < updateInterval
    }
    
    /**
     * Get user display name
     */
    fun getUserDisplayName(): String {
        val userInfo = currentUserInfo.get()
        return userInfo?.name ?: userInfo?.email ?: "Unknown User"
    }
    
    /**
     * Get user avatar URL
     */
    fun getUserAvatarUrl(): String? {
        return currentUserInfo.get()?.avatarUrl
    }
    
    /**
     * Check if user has usage limits
     */
    fun hasUsageLimits(): Boolean {
        return currentUserInfo.get()?.limits != null
    }
    
    /**
     * Get remaining requests
     */
    fun getRemainingRequests(): Long? {
        return currentUserInfo.get()?.limits?.requestsRemaining
    }
    
    /**
     * Update user information from the API
     */
    private fun updateUserInfo() {
        val settings = NeoaiSelfHostedSettings.getInstance()
        val baseUrl = settings.getServerUrl()
        val apiKey = settings.getApiKey()
        
        if (baseUrl.isEmpty() || apiKey.isEmpty()) {
            logger.debug("Server URL or API key not configured")
            return
        }
        
        try {
            val client = UserInfoClient.getInstance()
            val userInfo = client.fetchUserInfo(baseUrl, apiKey)
            
            if (userInfo != null) {
                currentUserInfo.set(userInfo)
                lastUpdateTime.set(System.currentTimeMillis())
                
                logger.debug("User info updated: ${userInfo.email}")
                
                // Notify listeners
                ApplicationManager.getApplication().messageBus.syncPublisher(USER_INFO_TOPIC)
                    .onUserInfoChanged(userInfo)
            } else {
                val error = "Failed to fetch user information"
                logger.warn(error)
                
                // Notify listeners of error
                ApplicationManager.getApplication().messageBus.syncPublisher(USER_INFO_TOPIC)
                    .onUserInfoError(error)
            }
        } catch (e: Exception) {
            val error = "Error updating user info: ${e.message}"
            logger.error(error)
            
            // Notify listeners of error
            ApplicationManager.getApplication().messageBus.syncPublisher(USER_INFO_TOPIC)
                .onUserInfoError(error)
        }
    }
    
    /**
     * Validate API key by making a test request
     */
    fun validateApiKey(baseUrl: String, apiKey: String): Boolean {
        return try {
            val client = UserInfoClient.getInstance()
            client.isUserInfoEndpointAccessible(baseUrl, apiKey)
        } catch (e: Exception) {
            logger.error("Error validating API key: ${e.message}")
            false
        }
    }
    
    /**
     * Dispose of resources
     */
    fun dispose() {
        stopUpdateLoop()
    }
}
