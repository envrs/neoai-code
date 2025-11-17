package com.neoai.assistant.settings;

import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.PersistentStateComponent;
import com.intellij.openapi.components.State;
import com.intellij.openapi.components.Storage;
import com.intellij.util.xmlb.XmlSerializerUtil;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.List;

/**
 * Settings for NeoAI Assistant
 */
@State(
    name = "NeoAISettings",
    storages = @Storage("NeoAISettings.xml")
)
public class NeoAISettings implements PersistentStateComponent<NeoAISettings.State> {
    
    public static class State {
        public boolean enabled = true;
        public String apiToken = "";
        public String apiUrl = "https://api.neoai.com";
        public String model = "neoai-coder";
        public int maxTokens = 1000;
        public double temperature = 0.1;
        public boolean telemetryEnabled = true;
        public List<String> disableFilePatterns = new ArrayList<>();
        public List<String> disableLinePatterns = new ArrayList<>();
        public boolean enableInlineCompletions = true;
        public boolean enableCodeGeneration = true;
        public boolean enableCodeExplanation = true;
        public int debounceMilliseconds = 500;
    }
    
    private State state = new State();
    
    public static NeoAISettings getInstance() {
        return ApplicationManager.getApplication().getService(NeoAISettings.class);
    }
    
    @Nullable
    @Override
    public State getState() {
        return state;
    }
    
    @Override
    public void loadState(@NotNull State state) {
        XmlSerializerUtil.copyBean(state, this.state);
    }
    
    // Getters and setters
    public boolean isEnabled() {
        return state.enabled;
    }
    
    public void setEnabled(boolean enabled) {
        state.enabled = enabled;
    }
    
    public String getApiToken() {
        return state.apiToken;
    }
    
    public void setApiToken(String apiToken) {
        state.apiToken = apiToken;
    }
    
    public String getApiUrl() {
        return state.apiUrl;
    }
    
    public void setApiUrl(String apiUrl) {
        state.apiUrl = apiUrl;
    }
    
    public String getModel() {
        return state.model;
    }
    
    public void setModel(String model) {
        state.model = model;
    }
    
    public int getMaxTokens() {
        return state.maxTokens;
    }
    
    public void setMaxTokens(int maxTokens) {
        state.maxTokens = maxTokens;
    }
    
    public double getTemperature() {
        return state.temperature;
    }
    
    public void setTemperature(double temperature) {
        state.temperature = temperature;
    }
    
    public boolean isTelemetryEnabled() {
        return state.telemetryEnabled;
    }
    
    public void setTelemetryEnabled(boolean telemetryEnabled) {
        state.telemetryEnabled = telemetryEnabled;
    }
    
    public List<String> getDisableFilePatterns() {
        return state.disableFilePatterns;
    }
    
    public void setDisableFilePatterns(List<String> disableFilePatterns) {
        state.disableFilePatterns = disableFilePatterns;
    }
    
    public List<String> getDisableLinePatterns() {
        return state.disableLinePatterns;
    }
    
    public void setDisableLinePatterns(List<String> disableLinePatterns) {
        state.disableLinePatterns = disableLinePatterns;
    }
    
    public boolean isEnableInlineCompletions() {
        return state.enableInlineCompletions;
    }
    
    public void setEnableInlineCompletions(boolean enableInlineCompletions) {
        state.enableInlineCompletions = enableInlineCompletions;
    }
    
    public boolean isEnableCodeGeneration() {
        return state.enableCodeGeneration;
    }
    
    public void setEnableCodeGeneration(boolean enableCodeGeneration) {
        state.enableCodeGeneration = enableCodeGeneration;
    }
    
    public boolean isEnableCodeExplanation() {
        return state.enableCodeExplanation;
    }
    
    public void setEnableCodeExplanation(boolean enableCodeExplanation) {
        state.enableCodeExplanation = enableCodeExplanation;
    }
    
    public int getDebounceMilliseconds() {
        return state.debounceMilliseconds;
    }
    
    public void setDebounceMilliseconds(int debounceMilliseconds) {
        state.debounceMilliseconds = debounceMilliseconds;
    }
    
    // Utility methods
    public boolean hasValidApiToken() {
        return state.apiToken != null && !state.apiToken.trim().isEmpty();
    }
}
