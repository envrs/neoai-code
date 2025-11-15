package com.neoaiSelfHosted.binary.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.service
import com.intellij.openapi.project.Project
import com.intellij.util.messages.MessageBusConnection
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.statusbar.StatusBarProvider
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * Central lifecycle manager for Neoai Self-Hosted plugin
 * Manages component lifecycle, health checks, and coordination
 */
@Service(Service.Level.APP)
class LifecycleManager {
    
    companion object {
        fun getInstance(): LifecycleManager = service()
        
        // Lifecycle states
        enum class State {
            INITIALIZING,
            RUNNING,
            PAUSED,
            STOPPING,
            STOPPED,
            ERROR
        }
        
        // Component states
        enum class ComponentState {
            HEALTHY,
            DEGRADED,
            FAILED,
            UNKNOWN
        }
    }
    
    private val currentState = AtomicReference(State.STOPPED)
    private val componentStates = ConcurrentHashMap<String, ComponentState>()
    private val components = ConcurrentHashMap<String, LifecycleComponent>()
    private val isInitialized = AtomicBoolean(false)
    private val messageBusConnection: MessageBusConnection = ApplicationManager.getApplication().messageBus.connect()
    private val scheduler: ScheduledExecutorService = Executors.newScheduledThreadPool(2)
    
    init {
        setupMessageBusListeners()
    }
    
    /**
     * Initialize the lifecycle manager
     */
    fun initialize() {
        if (isInitialized.getAndSet(true)) return
        
        setState(State.INITIALIZING)
        
        try {
            // Register core components
            registerComponent("UserInfoService", UserInfoService.getInstance())
            registerComponent("HealthChecker", HealthChecker.getInstance())
            registerComponent("ConnectionMonitor", ConnectionMonitor.getInstance())
            
            // Start health check scheduler
            scheduler.scheduleWithFixedDelay({
                performHealthCheck()
            }, 30, 30, TimeUnit.SECONDS)
            
            setState(State.RUNNING)
            StatusBarProvider.getInstance().showSuccessMessage("Lifecycle manager initialized")
            
        } catch (e: Exception) {
            setState(State.ERROR)
            StatusBarProvider.getInstance().updateErrorStatus("Failed to initialize lifecycle manager: ${e.message}")
        }
    }
    
    /**
     * Register a lifecycle component
     */
    fun registerComponent(name: String, component: LifecycleComponent) {
        components[name] = component
        componentStates[name] = ComponentState.UNKNOWN
        
        try {
            component.initialize()
            componentStates[name] = ComponentState.HEALTHY
        } catch (e: Exception) {
            componentStates[name] = ComponentState.FAILED
            println("Failed to initialize component $name: ${e.message}")
        }
    }
    
    /**
     * Unregister a lifecycle component
     */
    fun unregisterComponent(name: String) {
        val component = components.remove(name)
        component?.let {
            try {
                it.shutdown()
                componentStates.remove(name)
            } catch (e: Exception) {
                println("Error shutting down component $name: ${e.message}")
            }
        }
    }
    
    /**
     * Get current lifecycle state
     */
    fun getState(): State = currentState.get()
    
    /**
     * Set lifecycle state
     */
    private fun setState(state: State) {
        val oldState = currentState.getAndSet(state)
        if (oldState != state) {
            onStateChanged(oldState, state)
        }
    }
    
    /**
     * Handle state changes
     */
    private fun onStateChanged(oldState: State, newState: State) {
        when (newState) {
            State.RUNNING -> {
                StatusBarProvider.getInstance().updateConnectionStatus(true)
            }
            State.PAUSED -> {
                StatusBarProvider.getInstance().updateLoadingStatus("Paused")
            }
            State.STOPPING -> {
                StatusBarProvider.getInstance().updateLoadingStatus("Stopping...")
            }
            State.STOPPED -> {
                StatusBarProvider.getInstance().updateConnectionStatus(false)
            }
            State.ERROR -> {
                StatusBarProvider.getInstance().updateErrorStatus("Lifecycle error")
            }
            else -> {}
        }
    }
    
    /**
     * Perform health check on all components
     */
    private fun performHealthCheck() {
        if (getState() != State.RUNNING) return
        
        var hasDegraded = false
        var hasFailed = false
        
        components.forEach { (name, component) ->
            try {
                val isHealthy = component.isHealthy()
                componentStates[name] = if (isHealthy) ComponentState.HEALTHY else ComponentState.DEGRADED
                if (!isHealthy) hasDegraded = true
            } catch (e: Exception) {
                componentStates[name] = ComponentState.FAILED
                hasFailed = true
                println("Health check failed for component $name: ${e.message}")
            }
        }
        
        // Update overall status based on component health
        when {
            hasFailed -> {
                StatusBarProvider.getInstance().updateErrorStatus("Component failure detected")
            }
            hasDegraded -> {
                StatusBarProvider.getInstance().updateLoadingStatus("Some components degraded")
            }
            else -> {
                // All components healthy
                StatusBarProvider.getInstance().updateConnectionStatus(true)
            }
        }
    }
    
    /**
     * Get component state
     */
    fun getComponentState(name: String): ComponentState? {
        return componentStates[name]
    }
    
    /**
     * Get all component states
     */
    fun getAllComponentStates(): Map<String, ComponentState> {
        return componentStates.toMap()
    }
    
    /**
     * Pause lifecycle operations
     */
    fun pause() {
        if (getState() == State.RUNNING) {
            setState(State.PAUSED)
            components.forEach { (_, component) ->
                try {
                    component.pause()
                } catch (e: Exception) {
                    println("Error pausing component: ${e.message}")
                }
            }
        }
    }
    
    /**
     * Resume lifecycle operations
     */
    fun resume() {
        if (getState() == State.PAUSED) {
            setState(State.RUNNING)
            components.forEach { (_, component) ->
                try {
                    component.resume()
                } catch (e: Exception) {
                    println("Error resuming component: ${e.message}")
                }
            }
        }
    }
    
    /**
     * Shutdown the lifecycle manager
     */
    fun shutdown() {
        setState(State.STOPPING)
        
        // Shutdown all components
        components.forEach { (name, component) ->
            try {
                component.shutdown()
                componentStates[name] = ComponentState.UNKNOWN
            } catch (e: Exception) {
                println("Error shutting down component $name: ${e.message}")
            }
        }
        
        // Clear component registries
        components.clear()
        componentStates.clear()
        
        // Shutdown scheduler
        scheduler.shutdown()
        try {
            if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                scheduler.shutdownNow()
            }
        } catch (e: InterruptedException) {
            scheduler.shutdownNow()
        }
        
        // Disconnect message bus
        messageBusConnection.disconnect()
        
        setState(State.STOPPED)
        isInitialized.set(false)
    }
    
    /**
     * Setup message bus listeners
     */
    private fun setupMessageBusListeners() {
        messageBusConnection.subscribe(AppSettingsState.TOPIC, object : AppSettingsState.ChangeListener {
            override fun settingsChanged() {
                // Restart components if settings changed significantly
                if (getState() == State.RUNNING) {
                    performHealthCheck()
                }
            }
        })
    }
    
    /**
     * Force restart of all components
     */
    fun restart() {
        val wasRunning = getState() == State.RUNNING
        
        if (wasRunning) {
            pause()
        }
        
        // Clear and re-register components
        val componentNames = components.keys.toList()
        componentNames.forEach { unregisterComponent(it) }
        
        if (wasRunning) {
            initialize()
        }
    }
}

/**
 * Interface for lifecycle components
 */
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
    fun shutdown()
}
