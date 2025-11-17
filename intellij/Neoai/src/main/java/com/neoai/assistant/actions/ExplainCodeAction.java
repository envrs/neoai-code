package com.neoai.assistant.actions;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.ui.Messages;
import com.intellij.openapi.util.TextRange;
import com.neoai.assistant.service.NeoAIService;
import com.neoai.assistant.settings.NeoAISettings;
import org.jetbrains.annotations.NotNull;

/**
 * Action to explain code with AI
 */
public class ExplainCodeAction extends AnAction {
    
    @Override
    public void actionPerformed(@NotNull AnActionEvent e) {
        Project project = e.getProject();
        com.intellij.openapi.editor.Editor editor = e.getRequiredData(CommonDataKeys.EDITOR);
        NeoAISettings settings = NeoAISettings.getInstance();
        
        if (!settings.isEnabled() || !settings.isEnableCodeExplanation()) {
            Messages.showErrorDialog(
                "NeoAI code explanation is not enabled. Please enable it in settings.",
                "NeoAI Assistant"
            );
            return;
        }
        
        if (!settings.hasValidApiToken()) {
            Messages.showErrorDialog(
                "NeoAI API token is not configured. Please configure it in settings.",
                "NeoAI Assistant"
            );
            return;
        }
        
        // Get selected text
        String selectedText = getSelectedText(editor);
        if (selectedText == null || selectedText.trim().isEmpty()) {
            Messages.showErrorDialog(
                "Please select some code to explain.",
                "NeoAI Assistant"
            );
            return;
        }
        
        // Get language
        String language = editor.getDocument().toString(); // This would need proper language detection
        // For now, use a simple heuristic
        if (editor.getDocument().getText().contains("class ") && 
            editor.getDocument().getText().contains("public ")) {
            language = "java";
        } else if (editor.getDocument().getText().contains("def ") && 
                   editor.getDocument().getText().contains("import ")) {
            language = "python";
        } else if (editor.getDocument().getText().contains("function ") && 
                   editor.getDocument().getText().contains("const ")) {
            language = "javascript";
        } else {
            language = "text";
        }
        
        // Explain code asynchronously
        com.intellij.openapi.application.ApplicationManager.getApplication()
            .executeOnPooledThread(() -> {
                NeoAIService service = com.intellij.openapi.application.ApplicationManager
                    .getApplication().getService(NeoAIService.class);
                String explanation = service.explainCode(selectedText, language);
                
                // Show explanation on EDT
                com.intellij.openapi.application.ApplicationManager.getApplication()
                    .invokeLater(() -> {
                        if (explanation == null || explanation.trim().isEmpty()) {
                            Messages.showErrorDialog("Failed to explain code.", "NeoAI Assistant");
                            return;
                        }
                        
                        Messages.showInfoMessage(
                            project,
                            "Code Explanation:\n\n" + explanation,
                            "NeoAI Code Explanation"
                        );
                    });
            });
    }
    
    private String getSelectedText(com.intellij.openapi.editor.Editor editor) {
        com.intellij.openapi.editor.SelectionModel selectionModel = editor.getSelectionModel();
        if (selectionModel.hasSelection()) {
            return selectionModel.getSelectedText();
        }
        return null;
    }
    
    @Override
    public void update(@NotNull AnActionEvent e) {
        Project project = e.getProject();
        com.intellij.openapi.editor.Editor editor = e.getData(CommonDataKeys.EDITOR);
        NeoAISettings settings = NeoAISettings.getInstance();
        
        boolean enabled = project != null && 
                         editor != null && 
                         settings.isEnabled() && 
                         settings.isEnableCodeExplanation() &&
                         settings.hasValidApiToken() &&
                         editor.getSelectionModel().hasSelection();
        
        e.getPresentation().setEnabledAndVisible(enabled);
    }
}
