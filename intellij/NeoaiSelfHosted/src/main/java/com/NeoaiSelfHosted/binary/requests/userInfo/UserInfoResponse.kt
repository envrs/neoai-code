package com.neoaiSelfHosted.binary.requests.userInfo

import com.google.gson.annotations.SerializedName

/**
 * Response containing user information from the Neoai API
 */
data class UserInfoResponse(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("email")
    val email: String,
    
    @SerializedName("name")
    val name: String?,
    
    @SerializedName("avatar_url")
    val avatarUrl: String?,
    
    @SerializedName("profile")
    val profile: UserProfile?,
    
    @SerializedName("usage")
    val usage: UserUsage?,
    
    @SerializedName("limits")
    val limits: UserLimits?,
    
    @SerializedName("created_at")
    val createdAt: String,
    
    @SerializedName("updated_at")
    val updatedAt: String
)

/**
 * User profile information
 */
data class UserProfile(
    @SerializedName("bio")
    val bio: String?,
    
    @SerializedName("company")
    val company: String?,
    
    @SerializedName("location")
    val location: String?,
    
    @SerializedName("website")
    val website: String?,
    
    @SerializedName("timezone")
    val timezone: String?
)

/**
 * User usage statistics
 */
data class UserUsage(
    @SerializedName("requests_count")
    val requestsCount: Long,
    
    @SerializedName("tokens_used")
    val tokensUsed: Long,
    
    @SerializedName("storage_used")
    val storageUsed: Long,
    
    @SerializedName("last_request_at")
    val lastRequestAt: String?
)

/**
 * User limits and quotas
 */
data class UserLimits(
    @SerializedName("max_requests_per_day")
    val maxRequestsPerDay: Long?,
    
    @SerializedName("max_tokens_per_day")
    val maxTokensPerDay: Long?,
    
    @SerializedName("max_storage_mb")
    val maxStorageMb: Long?,
    
    @SerializedName("requests_remaining")
    val requestsRemaining: Long?,
    
    @SerializedName("tokens_remaining")
    val tokensRemaining: Long?,
    
    @SerializedName("storage_remaining_mb")
    val storageRemainingMb: Long?
)
