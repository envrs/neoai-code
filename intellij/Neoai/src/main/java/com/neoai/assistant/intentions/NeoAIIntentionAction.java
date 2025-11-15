package com.neoai.assistant.intentions;

import com.intellij.codeInsight.intention.IntentionAction;
import com.intellij.codeInsight.intention.PsiElementBaseIntentionAction;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.command.WriteCommandAction;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.ui.Messages;
import com.intellij.openapi.util.TextRange;
import com.intellij.psi.PsiDocumentManager;
import com.intellij.psi.PsiElement;
import com.intellij.psi.PsiFile;
import com.intellij.util.IncorrectOperationException;
import com.neoai.assistant.service.NeoAIService;
import com.neoai.assistant.settings.NeoAISettings;
import org.jetbrains.annotations.Nls;
import org.jetbrains.annotations.NotNull;

/**
 * Intention action to generate code with AI
 */
public class NeoAIIntentionAction extends PsiElementBaseIntentionAction implements IntentionAction {
    
    @Override
    public @Nls(capitalization = Nls.Capitalization.Sentence) @NotNull String getText() {
        return "Generate code with AI";
    }
    
    @Override
    public @Nls(capitalization = Nls.Capitalization.Sentence) @NotNull String getFamilyName() {
        return "NeoAI";
    }
    
    @Override
    public boolean isAvailable(@NotNull Project project, Editor editor, PsiElement element) {
        NeoAISettings settings = NeoAISettings.getInstance();
        return settings.isEnabled() && 
               settings.isEnableCodeGeneration() &&
               settings.hasValidApiToken();
    }
    
    @Override
    public void invoke(@NotNull Project project, Editor editor, PsiElement element) throws IncorrectOperationException {
        NeoAISettings settings = NeoAISettings.getInstance();
        
        if (!settings.isEnabled() || !settings.isEnableCodeGeneration()) {
            Messages.showErrorDialog(
                "NeoAI code generation is not enabled. Please enable it in settings.",
                "NeoAI Assistant"
            );
            return;
        }
        
        // Get context around the element
        String context = getContextText(element, editor);
        
        // Show input dialog for prompt
        String prompt = Messages.showInputDialog(
            project,
            "Enter your code generation prompt (context will be included automatically):",
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
            String fullPrompt = "Context:\n" + context + "\n\nRequest:\n" + prompt;
            String generatedCode = service.generateCode(project, fullPrompt);
            
            // Show result on EDT
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
    
    private String getContextText(PsiElement element, Editor editor) {
        PsiFile psiFile = element.getContainingFile();
        Document document = PsiDocumentManager.getInstance(element.getProject()).getDocument(psiFile);
        
        if (document == null) {
            return "";
        }
        
        // Get some context around the element
        int elementOffset = element.getTextOffset();
        int startOffset = Math.max(0, elementOffset - 200);
        int endOffset = Math.min(document.getTextLength(), elementOffset + 200);
        
        return document.getText(new TextRange(startOffset, endOffset));
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
    public boolean startInWriteAction() {
        return false;
    }
}
