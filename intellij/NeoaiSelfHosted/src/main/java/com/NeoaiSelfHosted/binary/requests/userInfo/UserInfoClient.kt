package com.neoaiSelfHosted.binary.requests.userInfo

import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import com.intellij.openapi.diagnostic.thisLogger
import com.neoaiSelfHosted.binary.http.HttpClientFactory
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Client for making user information requests to the Neoai API
 */
class UserInfoClient {
    private val gson = Gson()
    private val logger = thisLogger()
    
    /**
     * Fetch user information from the API
     * 
     * @param baseUrl The base URL of the Neoai API
     * @param apiKey The API key for authentication
     * @param request The user info request parameters
     * @return UserInfoResponse if successful, null otherwise
     */
    fun fetchUserInfo(
        baseUrl: String,
        apiKey: String,
        request: UserInfoRequest = UserInfoRequest()
    ): UserInfoResponse? {
        return try {
            val endpoint = "${baseUrl.trimEnd('/')}/api/v1/user/info"
            val url = URL(endpoint)
            
            logger.debug("Fetching user info from: $endpoint")
            
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("Authorization", "Bearer $apiKey")
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            val responseCode = connection.responseCode
            
            when (responseCode) {
                HttpURLConnection.HTTP_OK -> {
                    val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
                    logger.debug("User info response received successfully")
                    
                    try {
                        gson.fromJson(responseBody, UserInfoResponse::class.java)
                    } catch (e: JsonSyntaxException) {
                        logger.error("Failed to parse user info response: ${e.message}")
                        null
                    }
                }
                HttpURLConnection.HTTP_UNAUTHORIZED -> {
                    logger.warn("Unauthorized access to user info endpoint")
                    null
                }
                HttpURLConnection.HTTP_FORBIDDEN -> {
                    logger.warn("Forbidden access to user info endpoint")
                    null
                }
                else -> {
                    logger.error("Failed to fetch user info: HTTP $responseCode")
                    null
                }
            }
        } catch (e: IOException) {
            logger.error("Network error while fetching user info: ${e.message}")
            null
        } catch (e: Exception) {
            logger.error("Unexpected error while fetching user info: ${e.message}")
            null
        }
    }
    
    /**
     * Check if the user info endpoint is accessible
     * 
     * @param baseUrl The base URL of the Neoai API
     * @param apiKey The API key for authentication
     * @return true if accessible, false otherwise
     */
    fun isUserInfoEndpointAccessible(baseUrl: String, apiKey: String): Boolean {
        return try {
            val endpoint = "${baseUrl.trimEnd('/')}/api/v1/user/info"
            val url = URL(endpoint)
            
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "HEAD"
            connection.setRequestProperty("Authorization", "Bearer $apiKey")
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            
            val responseCode = connection.responseCode
            responseCode == HttpURLConnection.HTTP_OK
        } catch (e: Exception) {
            logger.debug("User info endpoint not accessible: ${e.message}")
            false
        }
    }
    
    companion object {
        @JvmStatic
        fun getInstance(): UserInfoClient {
            return UserInfoClient()
        }
    }
}
