package com.neoaiSelfHosted.statusbar

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.openapi.project.Project
import com.intellij.util.xmlb.XmlSerializerUtil
import com.intellij.util.xmlb.annotations.Tag

/**
 * Configuration for Neoai status bar widget
 */
@Service(Service.Level.PROJECT)
@State(name = "NeoaiStatusBarConfiguration", storages = [Storage("NeoaiStatusBarConfiguration.xml")])
class NeoaiStatusBarConfiguration : PersistentStateComponent<NeoaiStatusBarConfiguration.State> {
    
    data class State(
        @Tag var enabled: Boolean = true,
        @Tag var showConnectionStatus: Boolean = true,
        @Tag var showUrl: Boolean = false,
        @Tag var clickAction: ClickAction = ClickAction.OPEN_SETTINGS,
        @Tag var position: WidgetPosition = WidgetPosition.RIGHT,
        @Tag var showNotifications: Boolean = true,
        @Tag var updateInterval: Int = 30 // seconds
    )
    
    enum class ClickAction {
        OPEN_SETTINGS,
        SHOW_CONNECTION_DETAILS,
        TOGGLE_CHAT,
        OPEN_CHAT,
        NONE
    }
    
    enum class WidgetPosition {
        LEFT,
        RIGHT,
        BEFORE_POSITION,
        AFTER_POSITION
    }
    
    private var state = State()
    
    override fun getState(): State = state
    
    override fun loadState(state: State) {
        XmlSerializerUtil.copyBean(state, this.state)
    }
    
    companion object {
        fun getInstance(project: Project): NeoaiStatusBarConfiguration {
            return project.getService(NeoaiStatusBarConfiguration::class.java)
        }
    }
    
    /**
     * Check if the status bar widget is enabled
     */
    fun isEnabled(): Boolean = state.enabled
    
    /**
     * Enable or disable the status bar widget
     */
    fun setEnabled(enabled: Boolean) {
        state.enabled = enabled
    }
    
    /**
     * Check if connection status should be shown
     */
    fun shouldShowConnectionStatus(): Boolean = state.showConnectionStatus
    
    /**
     * Set whether to show connection status
     */
    fun setShowConnectionStatus(show: Boolean) {
        state.showConnectionStatus = show
    }
    
    /**
     * Check if URL should be shown in status
     */
    fun shouldShowUrl(): Boolean = state.showUrl
    
    /**
     * Set whether to show URL in status
     */
    fun setShowUrl(show: Boolean) {
        state.showUrl = show
    }
    
    /**
     * Get the click action for the widget
     */
    fun getClickAction(): ClickAction = state.clickAction
    
    /**
     * Set the click action for the widget
     */
    fun setClickAction(action: ClickAction) {
        state.clickAction = action
    }
    
    /**
     * Get the widget position
     */
    fun getPosition(): WidgetPosition = state.position
    
    /**
     * Set the widget position
     */
    fun setPosition(position: WidgetPosition) {
        state.position = position
    }
    
    /**
     * Check if notifications should be shown
     */
    fun shouldShowNotifications(): Boolean = state.showNotifications
    
    /**
     * Set whether to show notifications
     */
    fun setShowNotifications(show: Boolean) {
        state.showNotifications = show
    }
    
    /**
     * Get the update interval in seconds
     */
    fun getUpdateInterval(): Int = state.updateInterval
    
    /**
     * Set the update interval in seconds
     */
    fun setUpdateInterval(interval: Int) {
        state.updateInterval = interval.coerceIn(5, 300) // Between 5 seconds and 5 minutes
    }
    
    /**
     * Reset to default configuration
     */
    fun resetToDefaults() {
        state = State()
    }
}

/**
 * Settings provider for status bar configuration
 */
class NeoaiStatusBarSettings {
    
    companion object {
        /**
         * Get configuration for the given project
         */
        fun getConfiguration(project: Project): NeoaiStatusBarConfiguration {
            return NeoaiStatusBarConfiguration.getInstance(project)
        }
        
        /**
         * Check if status bar should be shown for the project
         */
        fun shouldShowStatusBar(project: Project): Boolean {
            return getConfiguration(project).isEnabled()
        }
        
        /**
         * Get the display text based on configuration
         */
        fun getDisplayText(project: Project, baseStatus: String, url: String? = null): String {
            val config = getConfiguration(project)
            var text = baseStatus
            
            if (config.shouldShowUrl() && url != null) {
                text += " ($url)"
            }
            
            return text
        }
        
        /**
         * Get the widget position string
         */
        fun getPositionString(position: NeoaiStatusBarConfiguration.WidgetPosition): String {
            return when (position) {
                NeoaiStatusBarConfiguration.WidgetPosition.LEFT -> "before Git"
                NeoaiStatusBarConfiguration.WidgetPosition.RIGHT -> "after Position"
                NeoaiStatusBarConfiguration.WidgetPosition.BEFORE_POSITION -> "before Position"
                NeoaiStatusBarConfiguration.WidgetPosition.AFTER_POSITION -> "after Position"
            }
        }
    }
}
