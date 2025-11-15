package com.neoai.intellij.completions;

import com.intellij.codeInsight.completion.*;
import com.intellij.codeInsight.lookup.LookupElementBuilder;
import com.intellij.patterns.PlatformPatterns;
import com.intellij.psi.PsiElement;
import com.intellij.util.ProcessingContext;
import org.jetbrains.annotations.NotNull;

/**
 * Main completion contributor for Neoai AI code completions.
 */
public class NeoaiCompletionContributor extends CompletionContributor {

    public NeoaiCompletionContributor() {
        extend(CompletionType.BASIC, 
               PlatformPatterns.psiElement(),
               new NeoaiCompletionProvider());
    }

    private static class NeoaiCompletionProvider extends CompletionProvider<CompletionParameters> {
        
        @Override
        protected void addCompletions(@NotNull CompletionParameters parameters,
                                    @NotNull ProcessingContext context,
                                    @NotNull CompletionResultSet result) {
            
            // Get context for AI completion
            PsiElement position = parameters.getPosition();
            String prefix = findPrefix(parameters);
            
            // Request AI completion (placeholder for actual implementation)
            String aiCompletion = requestAICompletion(prefix, position);
            
            if (aiCompletion != null && !aiCompletion.isEmpty()) {
                result.addElement(LookupElementBuilder.create(aiCompletion)
                        .withBoldness(true)
                        .withIcon(com.intellij.icons.AllIcons.Actions.Execute));
            }
        }
        
        private String findPrefix(@NotNull CompletionParameters parameters) {
            // Extract prefix from current position
            return parameters.getOriginalFile().getText()
                    .substring(0, parameters.getOffset());
        }
        
        private String requestAICompletion(@NotNull String prefix, @NotNull PsiElement position) {
            // Placeholder for AI completion request
            // This would integrate with the Neoai AI service
            return "ai_suggested_completion";
        }
    }
}
