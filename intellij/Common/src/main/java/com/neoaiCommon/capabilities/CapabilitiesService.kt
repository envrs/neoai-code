package com.neoaiCommon.capabilities

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.util.xmlb.XmlSerializerUtil
import java.util.concurrent.atomic.AtomicBoolean

@State(name = "CapabilitiesService", storages = [Storage("neoaiCapabilities.xml")])
@Service(Service.Level.APP)
class CapabilitiesService : PersistentStateComponent<CapabilitiesService.State>, com.neoaiCommon.lifecycle.LifecycleComponent {
    
    data class State(
        var inlineCompletionEnabled: Boolean = true,
        var chatEnabled: Boolean = false,
        var codeGenerationEnabled: Boolean = true,
        var supportedLanguages: MutableSet<String> = mutableSetOf("java", "kotlin", "python", "javascript", "typescript", "php", "rust"),
        var maxCompletionLength: Int = 100,
        var experimentalFeaturesEnabled: Boolean = false
    )
    
    private var state = State()
    private val initialized = AtomicBoolean(false)
    
    override fun getState(): State = state
    
    override fun loadState(state: State) {
        XmlSerializerUtil.copyBean(state, this.state)
    }
    
    override fun initialize() {
        if (initialized.getAndSet(true)) return
        // Initialize capabilities
    }
    
    override fun isHealthy(): Boolean {
        return initialized.get()
    }
    
    override fun shutdown() {
        initialized.set(false)
    }
    
    fun isInlineCompletionEnabled(): Boolean = state.inlineCompletionEnabled
    
    fun setInlineCompletionEnabled(enabled: Boolean) {
        state.inlineCompletionEnabled = enabled
    }
    
    fun isChatEnabled(): Boolean = state.chatEnabled
    
    fun setChatEnabled(enabled: Boolean) {
        state.chatEnabled = enabled
    }
    
    fun isCodeGenerationEnabled(): Boolean = state.codeGenerationEnabled
    
    fun setCodeGenerationEnabled(enabled: Boolean) {
        state.codeGenerationEnabled = enabled
    }
    
    fun getSupportedLanguages(): Set<String> = state.supportedLanguages.toSet()
    
    fun addSupportedLanguage(language: String) {
        state.supportedLanguages.add(language.lowercase())
    }
    
    fun removeSupportedLanguage(language: String) {
        state.supportedLanguages.remove(language.lowercase())
    }
    
    fun isLanguageSupported(language: String): Boolean {
        return state.supportedLanguages.contains(language.lowercase())
    }
    
    fun getMaxCompletionLength(): Int = state.maxCompletionLength
    
    fun setMaxCompletionLength(length: Int) {
        state.maxCompletionLength = maxOf(1, length)
    }
    
    fun isExperimentalFeaturesEnabled(): Boolean = state.experimentalFeaturesEnabled
    
    fun setExperimentalFeaturesEnabled(enabled: Boolean) {
        state.experimentalFeaturesEnabled = enabled
    }
    
    companion object {
        fun getInstance(): CapabilitiesService = service()
    }
}
