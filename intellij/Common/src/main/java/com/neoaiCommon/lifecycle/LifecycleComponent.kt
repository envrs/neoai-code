package com.neoaiCommon.lifecycle

interface LifecycleComponent {
    /**
     * Initialize the component
     */
    fun initialize()
    
    /**
     * Check if component is healthy
     */
    fun isHealthy(): Boolean
    
    /**
     * Pause component operations
     */
    fun pause() {}
    
    /**
     * Resume component operations
     */
    fun resume() {}
    
    /**
     * Shutdown the component
     */
    fun shutdown() {}
}
