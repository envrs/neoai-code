package com.neoaiCommon.userSettings

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.util.xmlb.XmlSerializerUtil
import com.intellij.util.messages.Topic
import java.util.concurrent.atomic.AtomicBoolean

@State(name = "AppSettingsState", storages = [Storage("neoaiSettings.xml")])
@Service(Service.Level.APP)
class AppSettingsState : PersistentStateComponent<AppSettingsState.State>, com.neoaiCommon.lifecycle.LifecycleComponent {
    
    data class State(
        var enabled: Boolean = true,
        var autoAcceptCompletions: Boolean = false,
        var completionDelay: Int = 500,
        var maxSuggestions: Int = 5,
        var inlineDelay: Int = 200,
        var showInlineHints: Boolean = true,
        var keyboardShortcutsEnabled: Boolean = true,
        var telemetryEnabled: Boolean = true,
        var debugMode: Boolean = false,
        var customApiKey: String? = null,
        var endpointUrl: String? = null,
        var proxyHost: String? = null,
        var proxyPort: Int = 0,
        var proxyEnabled: Boolean = false
    )
    
    private var state = State()
    private val initialized = AtomicBoolean(false)
    
    override fun getState(): State = state
    
    override fun loadState(state: State) {
        XmlSerializerUtil.copyBean(state, this.state)
    }
    
    override fun initialize() {
        if (initialized.getAndSet(true)) return
        // Initialize settings
    }
    
    override fun isHealthy(): Boolean {
        return initialized.get()
    }
    
    override fun shutdown() {
        initialized.set(false)
    }
    
    fun isEnabled(): Boolean = state.enabled
    
    fun setEnabled(enabled: Boolean) {
        state.enabled = enabled
    }
    
    fun isAutoAcceptCompletions(): Boolean = state.autoAcceptCompletions
    
    fun setAutoAcceptCompletions(autoAccept: Boolean) {
        state.autoAcceptCompletions = autoAccept
    }
    
    fun getCompletionDelay(): Int = state.completionDelay
    
    fun setCompletionDelay(delay: Int) {
        state.completionDelay = maxOf(0, delay)
    }
    
    fun getMaxSuggestions(): Int = state.maxSuggestions
    
    fun setMaxSuggestions(max: Int) {
        state.maxSuggestions = maxOf(1, max)
    }
    
    fun getInlineDelay(): Int = state.inlineDelay
    
    fun setInlineDelay(delay: Int) {
        state.inlineDelay = maxOf(0, delay)
    }
    
    fun showInlineHints(): Boolean = state.showInlineHints
    
    fun setShowInlineHints(show: Boolean) {
        state.showInlineHints = show
    }
    
    fun isKeyboardShortcutsEnabled(): Boolean = state.keyboardShortcutsEnabled
    
    fun setKeyboardShortcutsEnabled(enabled: Boolean) {
        state.keyboardShortcutsEnabled = enabled
    }
    
    fun isTelemetryEnabled(): Boolean = state.telemetryEnabled
    
    fun setTelemetryEnabled(enabled: Boolean) {
        state.telemetryEnabled = enabled
    }
    
    fun isDebugMode(): Boolean = state.debugMode
    
    fun setDebugMode(debug: Boolean) {
        state.debugMode = debug
    }
    
    fun getCustomApiKey(): String? = state.customApiKey
    
    fun setCustomApiKey(apiKey: String?) {
        state.customApiKey = apiKey
    }
    
    fun getEndpointUrl(): String? = state.endpointUrl
    
    fun setEndpointUrl(url: String?) {
        state.endpointUrl = url
    }
    
    fun getProxyHost(): String? = state.proxyHost
    
    fun setProxyHost(host: String?) {
        state.proxyHost = host
    }
    
    fun getProxyPort(): Int = state.proxyPort
    
    fun setProxyPort(port: Int) {
        state.proxyPort = maxOf(0, port)
    }
    
    fun isProxyEnabled(): Boolean = state.proxyEnabled
    
    fun setProxyEnabled(enabled: Boolean) {
        state.proxyEnabled = enabled
        notifySettingsChanged()
    }
    
    private fun notifySettingsChanged() {
        ApplicationManager.getApplication().messageBus.syncPublisher(TOPIC).settingsChanged()
    }
    
    companion object {
        val TOPIC = Topic.create("Neoai Settings Changed", ChangeListener::class.java)
        
        fun getInstance(): AppSettingsState = service()
    }
    
    interface ChangeListener {
        fun settingsChanged() {}
    }
}
