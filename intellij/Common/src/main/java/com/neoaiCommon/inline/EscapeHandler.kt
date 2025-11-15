package com.neoaiCommon.inline

import com.intellij.codeInsight.lookup.Lookup
import com.intellij.codeInsight.lookup.LookupManager
import com.intellij.openapi.actionSystem.DataContext
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.editor.actionSystem.EditorActionHandler
import com.intellij.openapi.project.Project

class EscapeHandler(editorActionHandler: EditorActionHandler) : EditorActionHandler() {
    
    private val originalHandler = editorActionHandler
    
    override fun doExecute(editor: Editor, caretContext: DataContext?) {
        val lookup = LookupManager.getActiveLookup(editor)
        
        if (lookup != null && isNeoaiLookup(lookup)) {
            lookup.hide()
            InlineCompletionManager.getInstance(editor.project!!).cancelCurrentCompletion()
        } else {
            originalHandler.execute(editor, caretContext)
        }
    }
    
    override fun isEnabledForCaret(editor: Editor, caretContext: DataContext?): Boolean {
        return originalHandler.isEnabled(editor, caretContext)
    }
    
    private fun isNeoaiLookup(lookup: Lookup): Boolean {
        return lookup.currentItem?.getUserData(InlineActionsPromoter.NEOAI_INLINE_COMPLETION_KEY) == true
    }
}
