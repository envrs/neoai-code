package com.neoai.assistant.completion;

import com.intellij.codeInsight.completion.*;
import com.intellij.codeInsight.lookup.LookupElementBuilder;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.editor.Document;
import com.intellij.openapi.editor.Editor;
import com.intellij.openapi.progress.ProgressManager;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.TextRange;
import com.intellij.patterns.PlatformPatterns;
import com.intellij.psi.PsiDocumentManager;
import com.intellij.psi.PsiElement;
import com.intellij.psi.PsiFile;
import com.intellij.util.ProcessingContext;
import com.neoai.assistant.service.NeoAIService;
import com.neoai.assistant.settings.NeoAISettings;
import org.jetbrains.annotations.NotNull;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * NeoAI completion provider for IntelliJ
 */
public class NeoAICompletionContributor extends CompletionContributor {
    
    private final NeoAIService neoAIService;
    private final NeoAISettings settings;
    
    public NeoAICompletionContributor() {
        this.neoAIService = ApplicationManager.getApplication().getService(NeoAIService.class);
        this.settings = ApplicationManager.getApplication().getService(NeoAISettings.class);
        
        extend(CompletionType.BASIC, 
               PlatformPatterns.psiElement(),
               new NeoAICompletionProvider());
               
        extend(CompletionType.SMART,
               PlatformPatterns.psiElement(),
               new NeoAICompletionProvider());
    }
    
    private class NeoAICompletionProvider extends CompletionProvider<CompletionParameters> {
        
        @Override
        protected void addCompletions(@NotNull CompletionParameters parameters,
                                   @NotNull ProcessingContext context,
                                   @NotNull CompletionResultSet result) {
            
            if (!settings.isEnabled()) {
                return;
            }
            
            Project project = parameters.getOriginalFile().getProject();
            Editor editor = parameters.getEditor();
            PsiFile psiFile = parameters.getOriginalFile();
            
            // Check if completion should be disabled for this file/line
            if (shouldDisableCompletion(editor, psiFile, parameters.getOffset())) {
                return;
            }
            
            // Get completion context
            CompletionContext completionContext = createCompletionContext(
                parameters, editor, psiFile);
            
            // Request AI completions asynchronously
            CompletableFuture.supplyAsync(() -> {
                try {
                    ProgressManager.checkCanceled();
                    return neoAIService.getCompletions(completionContext);
                } catch (Exception e) {
                    // Log error and return empty list
                    System.err.println("Error getting AI completions: " + e.getMessage());
                    return List.of();
                }
            }).orTimeout(5, TimeUnit.SECONDS)
              .thenAccept(completions -> {
                  // Add completions to result
                  for (NeoAICompletion completion : completions) {
                      LookupElementBuilder lookupElement = LookupElementBuilder
                          .create(completion.getText())
                          .withTailText(" (NeoAI)", true)
                          .withIcon(completion.getIcon())
                          .withTypeText(completion.getType())
                          .withInsertHandler(new NeoAIInsertHandler(completion));
                          
                      result.addElement(lookupElement);
                  }
              }).exceptionally(throwable -> {
                  // Handle timeout or other errors silently
                  return null;
              });
        }
        
        private boolean shouldDisableCompletion(Editor editor, PsiFile psiFile, int offset) {
            // Check file patterns
            List<String> disableFilePatterns = settings.getDisableFilePatterns();
            String filePath = psiFile.getVirtualFile().getPath();
            
            for (String pattern : disableFilePatterns) {
                try {
                    if (filePath.matches(pattern)) {
                        return true;
                    }
                } catch (Exception e) {
                    // Invalid regex pattern, log and continue
                    System.err.println("Invalid regex pattern: " + pattern);
                }
            }
            
            // Check line patterns
            List<String> disableLinePatterns = settings.getDisableLinePatterns();
            Document document = editor.getDocument();
            int lineNumber = document.getLineNumber(offset);
            int lineStart = document.getLineStartOffset(lineNumber);
            int lineEnd = document.getLineEndOffset(lineNumber);
            String lineText = document.getText(new TextRange(lineStart, lineEnd));
            
            for (String pattern : disableLinePatterns) {
                try {
                    if (lineText.matches(pattern)) {
                        return true;
                    }
                } catch (Exception e) {
                    // Invalid regex pattern, log and continue
                    System.err.println("Invalid regex pattern: " + pattern);
                }
            }
            
            // Check if in comment or string
            return isInCommentOrString(editor, psiFile, offset);
        }
        
        private boolean isInCommentOrString(Editor editor, PsiFile psiFile, int offset) {
            // Use PSI to determine if we're in a comment or string
            PsiElement element = psiFile.findElementAt(offset);
            if (element == null) {
                return false;
            }
            
            // Check parent elements for comment/string context
            PsiElement parent = element.getParent();
            while (parent != null) {
                String elementType = parent.getClass().getSimpleName().toLowerCase();
                if (elementType.contains("comment") || elementType.contains("string")) {
                    return true;
                }
                parent = parent.getParent();
            }
            
            return false;
        }
        
        private CompletionContext createCompletionContext(CompletionParameters parameters,
                                                         Editor editor,
                                                         PsiFile psiFile) {
            Document document = editor.getDocument();
            int offset = parameters.getOffset();
            
            // Get text before cursor
            String prefix = document.getText(new TextRange(0, offset));
            
            // Get current line
            int lineNumber = document.getLineNumber(offset);
            int lineStart = document.getLineStartOffset(lineNumber);
            int lineEnd = document.getLineEndOffset(lineNumber);
            String currentLine = document.getText(new TextRange(lineStart, lineEnd));
            
            // Get file content
            String fileContent = document.getText();
            
            // Get language
            String language = psiFile.getLanguage().getID();
            
            return new CompletionContext(
                prefix,
                currentLine,
                fileContent,
                language,
                offset,
                lineNumber,
                psiFile.getVirtualFile().getPath()
            );
        }
    }
}
