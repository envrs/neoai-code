package com.neoai.assistant.completion;

import com.intellij.codeInsight.completion.InsertHandler;
import com.intellij.codeInsight.completion.InsertionContext;
import com.intellij.codeInsight.lookup.LookupElement;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.command.WriteCommandAction;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.TextRange;
import com.neoai.assistant.service.NeoAIService;

/**
 * Insert handler for NeoAI completions
 */
public class NeoAIInsertHandler implements InsertHandler<LookupElement> {
    
    private final NeoAICompletion completion;
    
    public NeoAIInsertHandler(NeoAICompletion completion) {
        this.completion = completion;
    }
    
    @Override
    public void handleInsert(@NotNull InsertionContext context, @NotNull LookupElement item) {
        Project project = context.getProject();
        Editor editor = context.getEditor();
        Document document = editor.getDocument();
        
        // Handle additional text edits if present
        if (completion.hasAdditionalTextEdits()) {
            WriteCommandAction.runWriteCommandAction(project, () -> {
                // Apply additional text edits
                for (TextEdit edit : completion.getAdditionalTextEdits()) {
                    TextRange range = new TextRange(edit.getStartOffset(), edit.getEndOffset());
                    document.replaceString(range.getStartOffset(), range.getEndOffset(), edit.getText());
                }
            });
        }
        
        // Notify completion service that completion was accepted
        ApplicationManager.getApplication().getService(NeoAIService.class)
            .onCompletionAccepted(completion);
    }
}
