package com.neoaiCommon.userSettings

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.options.Configurable
import com.intellij.openapi.options.ConfigurationException
import com.intellij.openapi.util.NlsContexts
import com.intellij.ui.components.JBCheckBox
import com.intellij.ui.components.JBLabel
import com.intellij.ui.components.JBTextField
import com.intellij.util.ui.FormBuilder
import com.intellij.util.ui.JBUI
import java.awt.BorderLayout
import java.awt.GridBagConstraints
import java.awt.GridBagLayout
import javax.swing.*

class AppSettingsConfigurable : Configurable {
    
    private var settingsPanel: JPanel? = null
    private var enabledCheckBox: JBCheckBox? = null
    private var autoAcceptCheckBox: JBCheckBox? = null
    private var showHintsCheckBox: JBCheckBox? = null
    private var shortcutsCheckBox: JBCheckBox? = null
    private var telemetryCheckBox: JBCheckBox? = null
    private var debugCheckBox: JBCheckBox? = null
    private var proxyCheckBox: JBCheckBox? = null
    
    private var completionDelayField: JBTextField? = null
    private var maxSuggestionsField: JBTextField? = null
    private var inlineDelayField: JBTextField? = null
    private var apiKeyField: JBTextField? = null
    private var endpointUrlField: JBTextField? = null
    private var proxyHostField: JBTextField? = null
    private var proxyPortField: JBTextField? = null
    
    override fun getDisplayName(): @NlsContexts.ConfigurableName String {
        return "Neoai"
    }
    
    override fun createComponent(): JComponent? {
        settingsPanel = JPanel(BorderLayout())
        
        enabledCheckBox = JBCheckBox("Enable Neoai")
        autoAcceptCheckBox = JBCheckBox("Auto-accept completions")
        showHintsCheckBox = JBCheckBox("Show inline hints")
        shortcutsCheckBox = JBCheckBox("Enable keyboard shortcuts")
        telemetryCheckBox = JBCheckBox("Enable telemetry")
        debugCheckBox = JBCheckBox("Debug mode")
        proxyCheckBox = JBCheckBox("Use proxy")
        
        completionDelayField = JBTextField()
        maxSuggestionsField = JBTextField()
        inlineDelayField = JBTextField()
        apiKeyField = JBTextField()
        endpointUrlField = JBTextField()
        proxyHostField = JBTextField()
        proxyPortField = JBTextField()
        
        val formPanel = FormBuilder.createFormBuilder()
            .addComponent(enabledCheckBox, 1)
            .addLabeledComponent(JBLabel("Completion delay (ms):"), completionDelayField, 1, false)
            .addLabeledComponent(JBLabel("Max suggestions:"), maxSuggestionsField, 1, false)
            .addLabeledComponent(JBLabel("Inline delay (ms):"), inlineDelayField, 1, false)
            .addComponent(autoAcceptCheckBox, 1)
            .addComponent(showHintsCheckBox, 1)
            .addComponent(shortcutsCheckBox, 1)
            .addComponent(telemetryCheckBox, 1)
            .addComponent(debugCheckBox, 1)
            .addVerticalGap(10)
            .addComponent(JBLabel("Advanced Configuration"))
            .addLabeledComponent(JBLabel("API Key:"), apiKeyField, 1, false)
            .addLabeledComponent(JBLabel("Endpoint URL:"), endpointUrlField, 1, false)
            .addComponent(proxyCheckBox, 1)
            .addLabeledComponent(JBLabel("Proxy Host:"), proxyHostField, 1, false)
            .addLabeledComponent(JBLabel("Proxy Port:"), proxyPortField, 1, false)
            .addComponentFillVertically(JPanel(), 0)
            .panel
        
        settingsPanel!!.add(formPanel, BorderLayout.NORTH)
        
        proxyCheckBox!!.addActionListener {
            updateProxyFields()
        }
        
        return settingsPanel
    }
    
    private fun updateProxyFields() {
        val proxyEnabled = proxyCheckBox!!.isSelected
        proxyHostField!!.isEnabled = proxyEnabled
        proxyPortField!!.isEnabled = proxyEnabled
    }
    
    override fun isModified(): Boolean {
        val settings = AppSettingsState.getInstance()
        
        return enabledCheckBox!!.isSelected != settings.isEnabled() ||
                autoAcceptCheckBox!!.isSelected != settings.isAutoAcceptCompletions() ||
                showHintsCheckBox!!.isSelected != settings.showInlineHints() ||
                shortcutsCheckBox!!.isSelected != settings.isKeyboardShortcutsEnabled() ||
                telemetryCheckBox!!.isSelected != settings.isTelemetryEnabled() ||
                debugCheckBox!!.isSelected != settings.isDebugMode() ||
                proxyCheckBox!!.isSelected != settings.isProxyEnabled() ||
                completionDelayField!!.text != settings.getCompletionDelay().toString() ||
                maxSuggestionsField!!.text != settings.getMaxSuggestions().toString() ||
                inlineDelayField!!.text != settings.getInlineDelay().toString() ||
                apiKeyField!!.text != settings.getCustomApiKey() ||
                endpointUrlField!!.text != settings.getEndpointUrl() ||
                proxyHostField!!.text != settings.getProxyHost() ||
                proxyPortField!!.text != settings.getProxyPort().toString()
    }
    
    override fun apply() {
        val settings = AppSettingsState.getInstance()
        
        settings.setEnabled(enabledCheckBox!!.isSelected)
        settings.setAutoAcceptCompletions(autoAcceptCheckBox!!.isSelected)
        settings.setShowInlineHints(showHintsCheckBox!!.isSelected)
        settings.setKeyboardShortcutsEnabled(shortcutsCheckBox!!.isSelected)
        settings.setTelemetryEnabled(telemetryCheckBox!!.isSelected)
        settings.setDebugMode(debugCheckBox!!.isSelected)
        settings.setProxyEnabled(proxyCheckBox!!.isSelected)
        
        try {
            settings.setCompletionDelay(completionDelayField!!.text.toInt())
            settings.setMaxSuggestions(maxSuggestionsField!!.text.toInt())
            settings.setInlineDelay(inlineDelayField!!.text.toInt())
            settings.setProxyPort(proxyPortField!!.text.toInt())
        } catch (e: NumberFormatException) {
            throw ConfigurationException("Invalid numeric value")
        }
        
        settings.setCustomApiKey(apiKeyField!!.text.ifEmpty { null })
        settings.setEndpointUrl(endpointUrlField!!.text.ifEmpty { null })
        settings.setProxyHost(proxyHostField!!.text.ifEmpty { null })
    }
    
    override fun reset() {
        val settings = AppSettingsState.getInstance()
        
        enabledCheckBox!!.isSelected = settings.isEnabled()
        autoAcceptCheckBox!!.isSelected = settings.isAutoAcceptCompletions()
        showHintsCheckBox!!.isSelected = settings.showInlineHints()
        shortcutsCheckBox!!.isSelected = settings.isKeyboardShortcutsEnabled()
        telemetryCheckBox!!.isSelected = settings.isTelemetryEnabled()
        debugCheckBox!!.isSelected = settings.isDebugMode()
        proxyCheckBox!!.isSelected = settings.isProxyEnabled()
        
        completionDelayField!!.text = settings.getCompletionDelay().toString()
        maxSuggestionsField!!.text = settings.getMaxSuggestions().toString()
        inlineDelayField!!.text = settings.getInlineDelay().toString()
        apiKeyField!!.text = settings.getCustomApiKey() ?: ""
        endpointUrlField!!.text = settings.getEndpointUrl() ?: ""
        proxyHostField!!.text = settings.getProxyHost() ?: ""
        proxyPortField!!.text = settings.getProxyPort().toString()
        
        updateProxyFields()
    }
    
    override fun disposeUIResources() {
        settingsPanel = null
    }
}
