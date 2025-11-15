package com.neoaiSelfHosted.statusbar

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.wm.StatusBar
import com.intellij.openapi.wm.WindowManager
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.chat.SelfHostedChatEnabledState
import com.intellij.util.messages.MessageBusConnection
import com.intellij.util.ui.UIUtil

/**
 * Manager for Neoai status bar widgets across all projects
 */
class NeoaiStatusBarManager {
    
    companion object {
        private val instance = NeoaiStatusBarManager()
        
        fun getInstance(): NeoaiStatusBarManager = instance
    }
    
    private val messageBusConnection: MessageBusConnection = ApplicationManager.getApplication().messageBus.connect()
    private var isInitialized = false
    
    init {
        setupListeners()
    }
    
    /**
     * Initialize the status bar manager
     */
    fun initialize() {
        if (isInitialized) return
        
        // Update status bars for all existing projects
        ProjectManager.getInstance().openProjects.forEach { project ->
            updateProjectStatusBar(project)
        }
        
        isInitialized = true
    }
    
    /**
     * Setup listeners for configuration changes
     */
    private fun setupListeners() {
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
     * Update status bar for a specific project
     */
    private fun updateProjectStatusBar(project: Project) {
        ApplicationManager.getApplication().invokeLater {
            try {
                val statusBar = WindowManager.getInstance().getStatusBar(project)
                if (statusBar != null) {
                    val widget = statusBar.getWidget("NeoaiStatus") as? NeoaiStatusBarWidget
                    widget?.updateStatus()
                }
            } catch (e: Exception) {
                // Log error but don't crash
                println("Error updating status bar for project ${project.name}: ${e.message}")
            }
        }
    }
    
    /**
     * Update status bars for all open projects
     */
    fun updateAllStatusBars() {
        ProjectManager.getInstance().openProjects.forEach { project ->
            updateProjectStatusBar(project)
        }
    }
    
    /**
     * Update status bar with specific message
     */
    fun updateStatusWithMessage(message: String, project: Project? = null) {
        if (project != null) {
            updateProjectStatusBar(project)
        } else {
            updateAllStatusBars()
        }
    }
    
    /**
     * Show temporary status message
     */
    fun showTemporaryStatus(message: String, duration: Int = 5000, project: Project? = null) {
        val projects = if (project != null) listOf(project) else ProjectManager.getInstance().openProjects
        
        projects.forEach { proj ->
            ApplicationManager.getApplication().invokeLater {
                try {
                    val statusBar = WindowManager.getInstance().getStatusBar(proj)
                    if (statusBar != null) {
                        val widget = statusBar.getWidget("NeoaiStatus") as? NeoaiStatusBarWidget
                        if (widget is NeoaiStatusBarWidget) {
                            // Temporarily update the status
                            val originalPresentation = widget.presentation
                            // Create temporary presentation
                            val tempPresentation = NeoaiStatusBarPresentation()
                            tempPresentation.updateStatus()
                            
                            // Schedule revert after duration
                            ApplicationManager.getApplication().executeOnPooledThread {
                                Thread.sleep(duration.toLong())
                                ApplicationManager.getApplication().invokeLater {
                                    widget.updateStatus()
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    println("Error showing temporary status: ${e.message}")
                }
            }
        }
    }
    
    /**
     * Dispose of the manager
     */
    fun dispose() {
        messageBusConnection.disconnect()
        isInitialized = false
    }
}

/**
 * Status bar update utilities
 */
object StatusBarUpdater {
    
    /**
     * Update connection status
     */
    fun updateConnectionStatus(connected: Boolean, url: String? = null) {
        val manager = NeoaiStatusBarManager.getInstance()
        val message = if (connected) {
            "Neoai: Connected${url?.let { " to $it" } ?: ""}"
        } else {
            "Neoai: Disconnected"
        }
        manager.updateStatusWithMessage(message)
    }
    
    /**
     * Update error status
     */
    fun updateErrorStatus(error: String) {
        val manager = NeoaiStatusBarManager.getInstance()
        manager.updateStatusWithMessage("Neoai: Error - $error")
    }
    
    /**
     * Update loading status
     */
    fun updateLoadingStatus(message: String = "Connecting...") {
        val manager = NeoaiStatusBarManager.getInstance()
        manager.updateStatusWithMessage("Neoai: $message")
    }
    
    /**
     * Show success message
     */
    fun showSuccessMessage(message: String, duration: Int = 3000) {
        val manager = NeoaiStatusBarManager.getInstance()
        manager.showTemporaryStatus("Neoai: $message", duration)
    }
    
    /**
     * Show error message
     */
    fun showErrorMessage(message: String, duration: Int = 5000) {
        val manager = NeoaiStatusBarManager.getInstance()
        manager.showTemporaryStatus("Neoai: Error - $message", duration)
    }
}
