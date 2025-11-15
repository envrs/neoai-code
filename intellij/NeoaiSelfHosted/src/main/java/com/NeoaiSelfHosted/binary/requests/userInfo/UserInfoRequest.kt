package com.neoaiSelfHosted.binary.requests.userInfo

import com.google.gson.annotations.SerializedName

/**
 * Request for fetching user information from the Neoai API
 */
data class UserInfoRequest(
    @SerializedName("include_profile")
    val includeProfile: Boolean = true,
    
    @SerializedName("include_usage")
    val includeUsage: Boolean = false,
    
    @SerializedName("include_limits")
    val includeLimits: Boolean = false
)
