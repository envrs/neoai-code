package com.neoaiSelfHosted.statusbar

import com.intellij.openapi.project.Project
import com.intellij.openapi.util.Key
import com.intellij.openapi.wm.StatusBar
import com.intellij.openapi.wm.StatusBarWidget
import com.intellij.openapi.wm.StatusBarWidgetFactory
import com.intellij.openapi.wm.impl.status.widget.StatusBarEditorBasedWidgetFactory
import com.intellij.util.Consumer
import com.intellij.util.ui.UIUtil
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.chat.SelfHostedChatEnabledState
import java.awt.event.MouseEvent
import javax.swing.JComponent

/**
 * Status bar widget factory for Neoai plugin
 */
class NeoaiStatusBarWidgetFactory : StatusBarEditorBasedWidgetFactory("NeoaiStatus") {
    
    override fun createWidget(project: Project): StatusBarWidget {
        return NeoaiStatusBarWidget(project)
    }
    
    override fun canBeEnabledOn(statusBar: StatusBar): Boolean {
        return true
    }
    
    override fun getDisplayName(): String {
        return "Neoai Status"
    }
    
    override fun isConfigurable(): Boolean {
        return true
    }
}

/**
 * Status bar widget implementation
 */
class NeoaiStatusBarWidget(private val project: Project) : StatusBarWidget {
    
    companion object {
        private val WIDGET_KEY = Key.create<NeoaiStatusBarWidget>("NeoaiStatusBarWidget")
    }
    
    private var presentation = NeoaiStatusBarPresentation()
    private var component: JComponent? = null
    
    override fun ID(): String = "NeoaiStatus"
    
    override fun getPresentation(): StatusBarWidget.WidgetPresentation = presentation
    
    override fun install(statusBar: StatusBar) {
        component = presentation.getComponent()
        statusBar.addWidget(this, "before Position")
    }
    
    override fun dispose() {
        component = null
    }
    
    /**
     * Update the status bar display
     */
    fun updateStatus() {
        presentation.updateStatus()
    }
    
    /**
     * Get the widget instance for the given project
     */
    fun getInstance(project: Project): NeoaiStatusBarWidget? {
        return project.getUserData(WIDGET_KEY)
    }
    
    /**
     * Set the widget instance for the given project
     */
    fun setInstance(project: Project, widget: NeoaiStatusBarWidget) {
        project.putUserData(WIDGET_KEY, widget)
    }
}

/**
 * Presentation component for the status bar widget
 */
class NeoaiStatusBarPresentation : StatusBarWidget.TextPresentation {
    
    private var currentStatus = "Neoai: Disconnected"
    private var tooltipText = "Neoai Self-Hosted Plugin"
    private var isEnabled = false
    
    init {
        updateStatus()
    }
    
    override fun getText(): String = currentStatus
    
    override fun getTooltipText(): String = tooltipText
    
    override fun getClickConsumer(): Consumer<MouseEvent>? {
        return Consumer { event ->
            handleStatusClick(event)
        }
    }
    
    override fun getPreferredWidth(): Int {
        return UIUtil.stringWidth(currentStatus) + 20
    }
    
    override fun getComponent(): JComponent {
        return this as JComponent
    }
    
    /**
     * Update the status based on current plugin state
     */
    fun updateStatus() {
        val appSettings = AppSettingsState.instance
        val chatEnabled = SelfHostedChatEnabledState.instance.get().enabled
        
        isEnabled = chatEnabled
        
        when {
            !chatEnabled -> {
                currentStatus = "Neoai: Disabled"
                tooltipText = "Neoai Self-Hosted - Chat functionality is disabled"
            }
            appSettings.cloud2Url.isBlank() -> {
                currentStatus = "Neoai: No URL"
                tooltipText = "Neoai Self-Hosted - No server URL configured"
            }
            else -> {
                currentStatus = "Neoai: Connected"
                tooltipText = "Neoai Self-Hosted - Connected to ${appSettings.cloud2Url}"
            }
        }
    }
    
    /**
     * Handle click events on the status bar widget
     */
    private fun handleStatusClick(event: MouseEvent) {
        when {
            !isEnabled -> {
                // Show notification about enabling chat
                showEnableChatNotification()
            }
            AppSettingsState.instance.cloud2Url.isBlank() -> {
                // Open settings to configure URL
                openSettings()
            }
            else -> {
                // Show connection details
                showConnectionDetails()
            }
        }
    }
    
    /**
     * Show notification about enabling chat functionality
     */
    private fun showEnableChatNotification() {
        // Implementation would show a balloon notification
        // with instructions to enable chat functionality
    }
    
    /**
     * Open plugin settings
     */
    private fun openSettings() {
        // Implementation would open the settings dialog
        // and navigate to the Neoai configuration page
    }
    
    /**
     * Show connection details in a popup
     */
    private fun showConnectionDetails() {
        // Implementation would show a popup with connection details
        // including server URL, status, and available actions
    }
}
