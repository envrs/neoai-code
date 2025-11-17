package com.neoaiCommon.inline

import com.intellij.openapi.editor.Document
import com.intellij.openapi.editor.event.DocumentEvent
import com.intellij.openapi.editor.event.DocumentListener
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.psi.PsiDocumentManager
import com.intellij.psi.PsiFile

class NeoaiDocumentListener : DocumentListener {
    
    override fun documentChanged(event: DocumentEvent) {
        val document = event.document
        val project = getProjectForDocument(document) ?: return
        
        if (!shouldTriggerCompletion(document, event)) {
            return
        }
        
        val manager = InlineCompletionManager.getInstance(project)
        val settings = com.neoaiCommon.userSettings.AppSettingsState.getInstance()
        
        if (!settings.isEnabled()) {
            return
        }
        
        val delay = settings.getInlineDelay()
        if (delay > 0) {
            manager.scheduleCompletion(document, delay)
        } else {
            manager.triggerCompletion(document)
        }
    }
    
    private fun shouldTriggerCompletion(document: Document, event: DocumentEvent): Boolean {
        if (event.oldLength > 0 && event.newLength == 0) {
            return false
        }
        
        if (event.newLength > 10) {
            return false
        }
        
        val text = event.newFragment.toString()
        return text.isNotBlank() && !text.contains("\n")
    }
    
    private fun getProjectForDocument(document: Document): Project? {
        for (project in ProjectManager.getInstance().openProjects) {
            val psiFile = PsiDocumentManager.getInstance(project).getCachedPsiFile(document)
            if (psiFile != null) {
                return project
            }
        }
        return null
    }
}
