package com.neoaiSelfHosted.statusbar

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.service
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.wm.StatusBar
import com.intellij.openapi.wm.WindowManager
import com.intellij.util.messages.MessageBusConnection
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.chat.SelfHostedChatEnabledState
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Centralized service provider for Neoai status bar operations
 * Manages status bar instances and provides unified API for status updates
 */
@Service(Service.Level.APP)
class StatusBarProvider {
    
    companion object {
        fun getInstance(): StatusBarProvider = service()
    }
    
    private val statusBars = ConcurrentHashMap<Project, NeoaiStatusBarWidget>()
    private val isInitialized = AtomicBoolean(false)
    private val messageBusConnection: MessageBusConnection = ApplicationManager.getApplication().messageBus.connect()
    
    init {
        setupMessageBusListeners()
    }
    
    /**
     * Initialize the status bar provider
     */
    fun initialize() {
        if (isInitialized.getAndSet(true)) return
        
        // Register status bars for all existing projects
        ProjectManager.getInstance().openProjects.forEach { project ->
            registerStatusBar(project)
        }
        
        // Initialize the status bar manager
        NeoaiStatusBarManager.getInstance().initialize()
    }
    
    /**
     * Register a status bar widget for the given project
     */
    private fun registerStatusBar(project: Project) {
        try {
            val statusBar = WindowManager.getInstance().getStatusBar(project)
            if (statusBar != null) {
                // Create and register the widget
                val widget = NeoaiStatusBarWidget(project)
                statusBars[project] = widget
                
                // Update initial status
                updateStatusBarStatus(project)
            }
        } catch (e: Exception) {
            println("Error registering status bar for project ${project.name}: ${e.message}")
        }
    }
    
    /**
     * Unregister status bar widget for the given project
     */
    fun unregisterStatusBar(project: Project) {
        statusBars.remove(project)?.dispose()
    }
    
    /**
     * Get the status bar widget for the given project
     */
    fun getStatusBarWidget(project: Project): NeoaiStatusBarWidget? {
        return statusBars[project]
    }
    
    /**
     * Update status bar for a specific project
     */
    fun updateStatusBarStatus(project: Project) {
        val widget = statusBars[project]
        widget?.updateStatus()
    }
    
    /**
     * Update status bars for all projects
     */
    fun updateAllStatusBars() {
        statusBars.keys.forEach { project ->
            updateStatusBarStatus(project)
        }
    }
    
    /**
     * Show temporary status message on specific project
     */
    fun showTemporaryStatus(project: Project, message: String, duration: Int = 5000) {
        val widget = statusBars[project]
        widget?.let {
            NeoaiStatusBarManager.getInstance().showTemporaryStatus(message, duration, project)
        }
    }
    
    /**
     * Show temporary status message on all projects
     */
    fun showTemporaryStatusAll(message: String, duration: Int = 5000) {
        NeoaiStatusBarManager.getInstance().showTemporaryStatus(message, duration)
    }
    
    /**
     * Update connection status
     */
    fun updateConnectionStatus(connected: Boolean, url: String? = null, project: Project? = null) {
        if (project != null) {
            updateStatusBarStatus(project)
        } else {
            updateAllStatusBars()
        }
    }
    
    /**
     * Update error status
     */
    fun updateErrorStatus(error: String, project: Project? = null) {
        val message = "Neoai: Error - $error"
        if (project != null) {
            showTemporaryStatus(project, message, 5000)
        } else {
            showTemporaryStatusAll(message, 5000)
        }
    }
    
    /**
     * Update loading status
     */
    fun updateLoadingStatus(message: String = "Connecting...", project: Project? = null) {
        val fullMessage = "Neoai: $message"
        if (project != null) {
            showTemporaryStatus(project, fullMessage, 3000)
        } else {
            showTemporaryStatusAll(fullMessage, 3000)
        }
    }
    
    /**
     * Show success message
     */
    fun showSuccessMessage(message: String, project: Project? = null) {
        val fullMessage = "Neoai: $message"
        if (project != null) {
            showTemporaryStatus(project, fullMessage, 3000)
        } else {
            showTemporaryStatusAll(fullMessage, 3000)
        }
    }
    
    /**
     * Get current status text for a project
     */
    fun getCurrentStatusText(project: Project): String {
        val widget = statusBars[project]
        return widget?.presentation?.getText() ?: "Neoai: Unknown"
    }
    
    /**
     * Check if status bar is enabled for a project
     */
    fun isStatusBarEnabled(project: Project): Boolean {
        val config = NeoaiStatusBarConfiguration.getInstance(project)
        return config.isEnabled()
    }
    
    /**
     * Enable or disable status bar for a project
     */
    fun setStatusBarEnabled(project: Project, enabled: Boolean) {
        val config = NeoaiStatusBarConfiguration.getInstance(project)
        config.setEnabled(enabled)
        
        if (enabled) {
            registerStatusBar(project)
        } else {
            unregisterStatusBar(project)
        }
    }
    
    /**
     * Setup message bus listeners for configuration changes
     */
    private fun setupMessageBusListeners() {
        // Listen for app settings changes
        messageBusConnection.subscribe(AppSettingsState.TOPIC, object : AppSettingsState.ChangeListener {
            override fun settingsChanged() {
                updateAllStatusBars()
            }
        })
        
        // Listen for chat enabled state changes
        messageBusConnection.subscribe(SelfHostedChatEnabledState.TOPIC, object : SelfHostedChatEnabledState.ChangeListener {
            override fun enabledStateChanged(enabled: Boolean) {
                updateAllStatusBars()
            }
        })
    }
    
    /**
     * Get all registered status bar widgets
     */
    fun getAllStatusBars(): Map<Project, NeoaiStatusBarWidget> {
        return statusBars.toMap()
    }
    
    /**
     * Refresh status bar registration for all projects
     */
    fun refreshAllStatusBars() {
        // Clear existing registrations
        statusBars.clear()
        
        // Re-register for all current projects
        ProjectManager.getInstance().openProjects.forEach { project ->
            if (isStatusBarEnabled(project)) {
                registerStatusBar(project)
            }
        }
    }
    
    /**
     * Dispose of the provider
     */
    fun dispose() {
        // Dispose all status bar widgets
        statusBars.values.forEach { widget ->
            widget.dispose()
        }
        statusBars.clear()
        
        // Disconnect message bus
        messageBusConnection.disconnect()
        
        isInitialized.set(false)
    }
}

/**
 * Extension functions for convenient status bar operations
 */
fun Project.getNeoaiStatusBar(): NeoaiStatusBarWidget? {
    return StatusBarProvider.getInstance().getStatusBarWidget(this)
}

fun Project.updateNeoaiStatus() {
    StatusBarProvider.getInstance().updateStatusBarStatus(this)
}

fun Project.showNeoaiStatus(message: String, duration: Int = 5000) {
    StatusBarProvider.getInstance().showTemporaryStatus(this, message, duration)
}

fun Project.isNeoaiStatusBarEnabled(): Boolean {
    return StatusBarProvider.getInstance().isStatusBarEnabled(this)
}
