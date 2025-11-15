package com.neoaiSelfHosted.binary.requests.userInfo

import com.intellij.openapi.application.ApplicationManager
import com.intellij.util.messages.MessageBusConnection
import com.neoaiSelfHosted.binary.requests.userInfo.UserInfoService.UserInfoListener

/**
 * Utility class for working with user information
 */
object UserInfoUtil {
    
    /**
     * Format user display name with fallback
     */
    fun formatDisplayName(userInfo: UserInfoResponse?): String {
        if (userInfo == null) return "Unknown User"
        
        return userInfo.name ?: userInfo.email ?: "Unknown User"
    }
    
    /**
     * Get initials from user name
     */
    fun getInitials(userInfo: UserInfoResponse?): String {
        val displayName = formatDisplayName(userInfo)
        return displayName.split(" ")
            .mapNotNull { it.firstOrNull()?.uppercaseChar()?.toString() }
            .take(2)
            .joinToString("")
    }
    
    /**
     * Format user email for display
     */
    fun formatEmail(userInfo: UserInfoResponse?): String {
        return userInfo?.email ?: "No email"
    }
    
    /**
     * Check if user has profile information
     */
    fun hasProfileInfo(userInfo: UserInfoResponse?): Boolean {
        return userInfo?.profile != null
    }
    
    /**
     * Get user location
     */
    fun getLocation(userInfo: UserInfoResponse?): String {
        return userInfo?.profile?.location ?: "Unknown location"
    }
    
    /**
     * Get user company
     */
    fun getCompany(userInfo: UserInfoResponse?): String {
        return userInfo?.profile?.company ?: "Unknown company"
    }
    
    /**
     * Check if user has usage information
     */
    fun hasUsageInfo(userInfo: UserInfoResponse?): Boolean {
        return userInfo?.usage != null
    }
    
    /**
     * Format usage statistics
     */
    fun formatUsageStats(userInfo: UserInfoResponse?): String {
        val usage = userInfo?.usage ?: return "No usage data"
        
        return buildString {
            append("Requests: ${usage.requestsCount}")
            if (usage.tokensUsed > 0) {
                append(", Tokens: ${usage.tokensUsed}")
            }
            if (usage.storageUsed > 0) {
                append(", Storage: ${formatBytes(usage.storageUsed)}")
            }
        }
    }
    
    /**
     * Check if user has limits
     */
    fun hasLimits(userInfo: UserInfoResponse?): Boolean {
        return userInfo?.limits != null
    }
    
    /**
     * Format remaining requests
     */
    fun formatRemainingRequests(userInfo: UserInfoResponse?): String {
        val limits = userInfo?.limits ?: return "No limits"
        
        return if (limits.requestsRemaining != null) {
            "${limits.requestsRemaining} requests remaining"
        } else {
            "Unlimited requests"
        }
    }
    
    /**
     * Format remaining tokens
     */
    fun formatRemainingTokens(userInfo: UserInfoResponse?): String {
        val limits = userInfo?.limits ?: return "No limits"
        
        return if (limits.tokensRemaining != null) {
            "${limits.tokensRemaining} tokens remaining"
        } else {
            "Unlimited tokens"
        }
    }
    
    /**
     * Format storage usage
     */
    fun formatStorageUsage(userInfo: UserInfoResponse?): String {
        val limits = userInfo?.limits ?: return "No limits"
        
        return if (limits.storageRemainingMb != null && limits.maxStorageMb != null) {
            val used = limits.maxStorageMb - limits.storageRemainingMb
            "${formatBytes(used * 1024 * 1024)} / ${formatBytes(limits.maxStorageMb * 1024 * 1024)}"
        } else {
            "Unlimited storage"
        }
    }
    
    /**
     * Format bytes to human readable format
     */
    private fun formatBytes(bytes: Long): String {
        val units = arrayOf("B", "KB", "MB", "GB", "TB")
        var size = bytes.toDouble()
        var unitIndex = 0
        
        while (size >= 1024 && unitIndex < units.size - 1) {
            size /= 1024
            unitIndex++
        }
        
        return "%.1f %s".format(size, units[unitIndex])
    }
    
    /**
     * Format account creation date
     */
    fun formatCreationDate(userInfo: UserInfoResponse?): String {
        return userInfo?.createdAt ?: "Unknown"
    }
    
    /**
     * Check if user account is premium
     */
    fun isPremiumUser(userInfo: UserInfoResponse?): Boolean {
        // This could be based on limits or other indicators
        return userInfo?.limits?.let { limits ->
            // If user has high limits, consider them premium
            limits.maxRequestsPerDay != null && limits.maxRequestsPerDay > 1000 ||
            limits.maxTokensPerDay != null && limits.maxTokensPerDay > 100000
        } ?: false
    }
    
    /**
     * Subscribe to user info changes
     */
    fun subscribe(listener: UserInfoListener): MessageBusConnection {
        val connection = ApplicationManager.getApplication().messageBus.connect()
        connection.subscribe(UserInfoService.USER_INFO_TOPIC, listener)
        return connection
    }
    
    /**
     * Get current user info safely
     */
    fun getCurrentUserInfo(): UserInfoResponse? {
        return UserInfoService.getInstance().currentUserInfo
    }
    
    /**
     * Refresh user info
     */
    fun refreshUserInfo() {
        UserInfoService.getInstance().refreshUserInfo()
    }
}
