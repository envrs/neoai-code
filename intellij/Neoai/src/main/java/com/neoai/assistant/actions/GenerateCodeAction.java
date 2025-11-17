package com.neoai.assistant.actions;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.command.WriteCommandAction;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.editor.SelectionModel;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.ui.Messages;
import com.intellij.openapi.util.TextRange;
import com.neoai.assistant.service.NeoAIService;
import com.neoai.assistant.settings.NeoAISettings;
import org.jetbrains.annotations.NotNull;

/**
 * Action to generate code with AI
 */
public class GenerateCodeAction extends AnAction {
    
    @Override
    public void actionPerformed(@NotNull AnActionEvent e) {
        Project project = e.getProject();
        Editor editor = e.getRequiredData(CommonDataKeys.EDITOR);
        NeoAISettings settings = NeoAISettings.getInstance();
        
        if (!settings.isEnabled() || !settings.isEnableCodeGeneration()) {
            Messages.showErrorDialog(
                "NeoAI code generation is not enabled. Please enable it in settings.",
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
        
        // Get selected text or current line
        String selectedText = getSelectedText(editor);
        if (selectedText == null) {
            selectedText = getCurrentLineText(editor);
        }
        
        // Show input dialog for prompt
        String prompt = Messages.showInputDialog(
            project,
            "Enter your code generation prompt:",
            "Generate Code with AI",
            Messages.getQuestionIcon(),
            "",
            null
        );
        
        if (prompt == null || prompt.trim().isEmpty()) {
            return;
        }
        
        // Generate code asynchronously
        ApplicationManager.getApplication().executeOnPooledThread(() -> {
            NeoAIService service = ApplicationManager.getApplication().getService(NeoAIService.class);
            String generatedCode = service.generateCode(project, prompt);
            
            // Insert generated code on EDT
            ApplicationManager.getApplication().invokeLater(() -> {
                if (generatedCode == null || generatedCode.trim().isEmpty()) {
                    Messages.showErrorDialog("Failed to generate code.", "NeoAI Assistant");
                    return;
                }
                
                // Show result in a dialog
                int result = Messages.showYesNoDialog(
                    project,
                    "Generated code:\n\n" + generatedCode + "\n\nInsert this code?",
                    "NeoAI Code Generation",
                    "Insert", "Cancel", Messages.getQuestionIcon()
                );
                
                if (result == Messages.YES) {
                    insertGeneratedCode(editor, generatedCode);
                }
            });
        });
    }
    
    private String getSelectedText(Editor editor) {
        SelectionModel selectionModel = editor.getSelectionModel();
        if (selectionModel.hasSelection()) {
            return selectionModel.getSelectedText();
        }
        return null;
    }
    
    private String getCurrentLineText(Editor editor) {
        Document document = editor.getDocument();
        int caretOffset = editor.getCaretModel().getOffset();
        int lineNumber = document.getLineNumber(caretOffset);
        int lineStart = document.getLineStartOffset(lineNumber);
        int lineEnd = document.getLineEndOffset(lineNumber);
        return document.getText(new TextRange(lineStart, lineEnd));
    }
    
    private void insertGeneratedCode(Editor editor, String generatedCode) {
        WriteCommandAction.runWriteCommandAction(editor.getProject(), () -> {
            Document document = editor.getDocument();
            int offset = editor.getCaretModel().getOffset();
            
            // Insert the generated code
            document.insertString(offset, generatedCode);
            
            // Move cursor to end of inserted text
            editor.getCaretModel().moveToOffset(offset + generatedCode.length());
        });
    }
    
    @Override
    public void update(@NotNull AnActionEvent e) {
        Project project = e.getProject();
        Editor editor = e.getData(CommonDataKeys.EDITOR);
        NeoAISettings settings = NeoAISettings.getInstance();
        
        boolean enabled = project != null && 
                         editor != null && 
                         settings.isEnabled() && 
                         settings.isEnableCodeGeneration() &&
                         settings.hasValidApiToken();
        
        e.getPresentation().setEnabledAndVisible(enabled);
    }
}
