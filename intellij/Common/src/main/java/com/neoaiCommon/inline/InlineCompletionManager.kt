package com.neoaiCommon.inline

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.editor.Document
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.Computable
import com.intellij.util.ui.update.MergingUpdateQueue
import com.intellij.util.ui.update.Update
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

@Service(Service.Level.PROJECT)
class InlineCompletionManager(private val project: Project) : com.neoaiCommon.lifecycle.LifecycleComponent {
    
    private val completionActive = AtomicBoolean(false)
    private val currentDocument = AtomicReference<Document>()
    private val completionQueue = MergingUpdateQueue("neoai-inline-completion", 100, true, null, project)
    
    fun triggerCompletion(document: Document) {
        if (completionActive.compareAndSet(false, true)) {
            currentDocument.set(document)
            
            ApplicationManager.getApplication().invokeLater {
                try {
                    performCompletion(document)
                } finally {
                    completionActive.set(false)
                    currentDocument.set(null)
                }
            }
        }
    }
    
    fun scheduleCompletion(document: Document, delayMs: Int) {
        completionQueue.queue(Update.create("neoai-completion") {
            triggerCompletion(document)
        })
    }
    
    private fun performCompletion(document: Document) {
        val editor = getEditorForDocument(document) ?: return
        val capabilities = com.neoaiCommon.capabilities.CapabilitiesService.getInstance()
        
        if (!capabilities.isInlineCompletionEnabled()) {
            return
        }
        
        val offset = editor.caretModel.offset
        val text = document.text
        
        if (text.isEmpty() || offset >= text.length) {
            return
        }
        
        val context = extractCompletionContext(text, offset)
        val suggestions = generateCompletions(context)
        
        if (suggestions.isNotEmpty()) {
            showInlineSuggestions(editor, suggestions)
        }
    }
    
    private fun extractCompletionContext(text: String, offset: Int): String {
        val start = maxOf(0, offset - 500)
        return text.substring(start, offset)
    }
    
    private fun generateCompletions(context: String): List<String> {
        return emptyList()
    }
    
    private fun showInlineSuggestions(editor: Editor, suggestions: List<String>) {
        
    }
    
    private fun getEditorForDocument(document: Document): Editor? {
        return ApplicationManager.getApplication().runReadAction(Computable {
            com.intellij.openapi.fileEditor.FileEditorManager.getInstance(project).selectedTextEditor
        })
    }
    
    fun cancelCurrentCompletion() {
        completionActive.set(false)
        currentDocument.set(null)
        completionQueue.cancelAllUpdates()
    }
    
    override fun initialize() {
        // Initialize inline completion manager
    }
    
    override fun isHealthy(): Boolean {
        return true
    }
    
    override fun shutdown() {
        cancelCurrentCompletion()
        completionQueue.dispose()
    }
    
    companion object {
        fun getInstance(project: Project): InlineCompletionManager = service(project)
    }
}
