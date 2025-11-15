package com.neoai.assistant.settings;

import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.options.Configurable;
import com.intellij.openapi.options.ConfigurationException;
import com.intellij.openapi.util.NlsContexts;
import com.intellij.ui.components.JBCheckBox;
import com.intellij.ui.components.JBLabel;
import com.intellij.ui.components.JBPasswordField;
import com.intellij.ui.components.JBTextField;
import com.intellij.util.ui.FormBuilder;
import org.jetbrains.annotations.Nls;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import java.awt.*;
import java.util.Arrays;

/**
 * Settings UI for NeoAI Assistant
 */
public class NeoAISettingsConfigurable implements Configurable {
    
    private NeoAISettings settings;
    
    private JBCheckBox enabledCheckBox;
    private JBPasswordField apiTokenField;
    private JBTextField apiUrlField;
    private JBTextField modelField;
    private JBTextField maxTokensField;
    private JBTextField temperatureField;
    private JBCheckBox telemetryCheckBox;
    private JBCheckBox inlineCompletionsCheckBox;
    private JBCheckBox codeGenerationCheckBox;
    private JBCheckBox codeExplanationCheckBox;
    private JBTextField debounceField;
    private JBTextArea disableFilePatternsArea;
    private JBTextArea disableLinePatternsArea;
    
    @Nls(capitalization = Nls.Capitalization.Title)
    @Override
    public @NlsContexts.ConfigurableName String getDisplayName() {
        return "NeoAI Assistant";
    }
    
    @Override
    public @Nullable JComponent createComponent() {
        settings = NeoAISettings.getInstance();
        
        // Create UI components
        enabledCheckBox = new JBCheckBox("Enable NeoAI Assistant");
        apiTokenField = new JBPasswordField();
        apiUrlField = new JBTextField();
        modelField = new JBTextField();
        maxTokensField = new JBTextField();
        temperatureField = new JBTextField();
        telemetryCheckBox = new JBCheckBox("Enable telemetry");
        inlineCompletionsCheckBox = new JBCheckBox("Enable inline completions");
        codeGenerationCheckBox = new JBCheckBox("Enable code generation");
        codeExplanationCheckBox = new JBCheckBox("Enable code explanation");
        debounceField = new JBTextField();
        disableFilePatternsArea = new JBTextArea(3, 20);
        disableLinePatternsArea = new JBTextArea(3, 20);
        
        // Set up text areas with scroll panes
        JScrollPane filePatternsScroll = new JScrollPane(disableFilePatternsArea);
        JScrollPane linePatternsScroll = new JScrollPane(disableLinePatternsArea);
        
        // Add validation listeners
        setupValidation();
        
        // Build form
        return FormBuilder.createFormBuilder()
            .addComponent(enabledCheckBox)
            .addLabeledComponent(new JBLabel("API Token:"), apiTokenField)
            .addLabeledComponent(new JBLabel("API URL:"), apiUrlField)
            .addLabeledComponent(new JBLabel("Model:"), modelField)
            .addLabeledComponent(new JBLabel("Max Tokens:"), maxTokensField)
            .addLabeledComponent(new JBLabel("Temperature:"), temperatureField)
            .addComponent(telemetryCheckBox)
            .addComponent(inlineCompletionsCheckBox)
            .addComponent(codeGenerationCheckBox)
            .addComponent(codeExplanationCheckBox)
            .addLabeledComponent(new JBLabel("Debounce (ms):"), debounceField)
            .addLabeledComponent(new JBLabel("Disable File Patterns (one per line):"), filePatternsScroll)
            .addLabeledComponent(new JBLabel("Disable Line Patterns (one per line):"), linePatternsScroll)
            .addComponentFillVertically(new JPanel(), 0)
            .getPanel();
    }
    
    private void setupValidation() {
        DocumentListener validationListener = new DocumentListener() {
            @Override
            public void insertUpdate(DocumentEvent e) { validateFields(); }
            @Override
            public void removeUpdate(DocumentEvent e) { validateFields(); }
            @Override
            public void changedUpdate(DocumentEvent e) { validateFields(); }
        };
        
        apiTokenField.getDocument().addDocumentListener(validationListener);
        apiUrlField.getDocument().addDocumentListener(validationListener);
        maxTokensField.getDocument().addDocumentListener(validationListener);
        temperatureField.getDocument().addDocumentListener(validationListener);
        debounceField.getDocument().addDocumentListener(validationListener);
    }
    
    private void validateFields() {
        // Validate numeric fields
        if (!maxTokensField.getText().matches("\\d+")) {
            maxTokensField.setForeground(Color.RED);
        } else {
            maxTokensField.setForeground(UIManager.getColor("TextField.foreground"));
        }
        
        if (!temperatureField.getText().matches("\\d+(\\.\\d+)?")) {
            temperatureField.setForeground(Color.RED);
        } else {
            temperatureField.setForeground(UIManager.getColor("TextField.foreground"));
        }
        
        if (!debounceField.getText().matches("\\d+")) {
            debounceField.setForeground(Color.RED);
        } else {
            debounceField.setForeground(UIManager.getColor("TextField.foreground"));
        }
    }
    
    @Override
    public boolean isModified() {
        return !enabledCheckBox.isSelected() == settings.isEnabled() ||
               !String.valueOf(apiTokenField.getPassword()).equals(settings.getApiToken()) ||
               !apiUrlField.getText().equals(settings.getApiUrl()) ||
               !modelField.getText().equals(settings.getModel()) ||
               !maxTokensField.getText().equals(String.valueOf(settings.getMaxTokens())) ||
               !temperatureField.getText().equals(String.valueOf(settings.getTemperature())) ||
               telemetryCheckBox.isSelected() != settings.isTelemetryEnabled() ||
               inlineCompletionsCheckBox.isSelected() != settings.isEnableInlineCompletions() ||
               codeGenerationCheckBox.isSelected() != settings.isEnableCodeGeneration() ||
               codeExplanationCheckBox.isSelected() != settings.isEnableCodeExplanation() ||
               !debounceField.getText().equals(String.valueOf(settings.getDebounceMilliseconds())) ||
               !Arrays.equals(disableFilePatternsArea.getText().split("\n"), 
                            settings.getDisableFilePatterns().toArray()) ||
               !Arrays.equals(disableLinePatternsArea.getText().split("\n"), 
                            settings.getDisableLinePatterns().toArray());
    }
    
    @Override
    public void apply() throws ConfigurationException {
        // Validate fields before applying
        if (!maxTokensField.getText().matches("\\d+")) {
            throw new ConfigurationException("Max tokens must be a positive integer");
        }
        
        if (!temperatureField.getText().matches("\\d+(\\.\\d+)?")) {
            throw new ConfigurationException("Temperature must be a number");
        }
        
        if (!debounceField.getText().matches("\\d+")) {
            throw new ConfigurationException("Debounce must be a positive integer");
        }
        
        // Apply settings
        settings.setEnabled(enabledCheckBox.isSelected());
        settings.setApiToken(String.valueOf(apiTokenField.getPassword()));
        settings.setApiUrl(apiUrlField.getText());
        settings.setModel(modelField.getText());
        settings.setMaxTokens(Integer.parseInt(maxTokensField.getText()));
        settings.setTemperature(Double.parseDouble(temperatureField.getText()));
        settings.setTelemetryEnabled(telemetryCheckBox.isSelected());
        settings.setEnableInlineCompletions(inlineCompletionsCheckBox.isSelected());
        settings.setEnableCodeGeneration(codeGenerationCheckBox.isSelected());
        settings.setEnableCodeExplanation(codeExplanationCheckBox.isSelected());
        settings.setDebounceMilliseconds(Integer.parseInt(debounceField.getText()));
        
        // Split patterns by lines
        settings.setDisableFilePatterns(Arrays.asList(disableFilePatternsArea.getText().split("\n")));
        settings.setDisableLinePatterns(Arrays.asList(disableLinePatternsArea.getText().split("\n")));
    }
    
    @Override
    public void reset() {
        enabledCheckBox.setSelected(settings.isEnabled());
        apiTokenField.setText(settings.getApiToken());
        apiUrlField.setText(settings.getApiUrl());
        modelField.setText(settings.getModel());
        maxTokensField.setText(String.valueOf(settings.getMaxTokens()));
        temperatureField.setText(String.valueOf(settings.getTemperature()));
        telemetryCheckBox.setSelected(settings.isTelemetryEnabled());
        inlineCompletionsCheckBox.setSelected(settings.isEnableInlineCompletions());
        codeGenerationCheckBox.setSelected(settings.isEnableCodeGeneration());
        codeExplanationCheckBox.setSelected(settings.isEnableCodeExplanation());
        debounceField.setText(String.valueOf(settings.getDebounceMilliseconds()));
        
        // Join patterns with newlines
        disableFilePatternsArea.setText(String.join("\n", settings.getDisableFilePatterns()));
        disableLinePatternsArea.setText(String.join("\n", settings.getDisableLinePatterns()));
    }
    
    @Override
    public void disposeUIResources() {
        enabledCheckBox = null;
        apiTokenField = null;
        apiUrlField = null;
        modelField = null;
        maxTokensField = null;
        temperatureField = null;
        telemetryCheckBox = null;
        inlineCompletionsCheckBox = null;
        codeGenerationCheckBox = null;
        codeExplanationCheckBox = null;
        debounceField = null;
        disableFilePatternsArea = null;
        disableLinePatternsArea = null;
    }
}
