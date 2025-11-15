package com.neoai.chat.actions;

import com.intellij.codeInsight.intention.IntentionAction;
import com.intellij.codeInsight.intention.PsiElementBaseIntentionAction;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.project.Project;
import com.intellij.psi.PsiElement;
import com.intellij.psi.PsiFile;
import com.intellij.util.IncorrectOperationException;
import org.jetbrains.annotations.Nls;
import org.jetbrains.annotations.NotNull;

/**
 * Neoai quick fix intention action for AI-powered code suggestions.
 */
public class NeoaiQuickFixAction extends PsiElementBaseIntentionAction implements IntentionAction {

    @Nls(capitalization = Nls.Capitalization.Sentence)
    @NotNull
    @Override
    public String getText() {
        return "Get AI suggestion from Neoai";
    }

    @Nls(capitalization = Nls.Capitalization.Sentence)
    @NotNull
    @Override
    public String getFamilyName() {
        return "Neoai intentions";
    }

    @Override
    public boolean isAvailable(@NotNull Project project, Editor editor, PsiElement element) {
        // Check if AI suggestion is available for this context
        return element != null && element.getContainingFile() != null;
    }

    @Override
    public void invoke(@NotNull Project project, Editor editor, PsiElement element) throws IncorrectOperationException {
        // Get AI suggestion and apply it
        String suggestion = getAISuggestion(element, project);
        if (suggestion != null && !suggestion.isEmpty()) {
            applySuggestion(editor, element, suggestion);
        }
    }

    @Override
    public boolean startInWriteAction() {
        return true;
    }

    private String getAISuggestion(@NotNull PsiElement element, @NotNull Project project) {
        // Placeholder for AI suggestion logic
        // This would integrate with the Neoai AI service
        return "// AI suggested improvement";
    }

    private void applySuggestion(@NotNull Editor editor, @NotNull PsiElement element, @NotNull String suggestion) {
        // Apply the AI suggestion to the code
        // This would replace or modify the selected element
        int startOffset = element.getTextRange().getStartOffset();
        int endOffset = element.getTextRange().getEndOffset();
        
        editor.getDocument().replaceString(startOffset, endOffset, suggestion);
    }
}
