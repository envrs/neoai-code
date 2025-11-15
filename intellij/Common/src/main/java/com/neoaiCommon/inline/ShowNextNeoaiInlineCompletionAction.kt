package com.neoaiCommon.inline

import com.intellij.codeInsight.lookup.Lookup
import com.intellij.codeInsight.lookup.LookupManager
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.editor.Editor

class ShowNextNeoaiInlineCompletionAction : AnAction() {
    
    override fun actionPerformed(e: AnActionEvent) {
        val editor = e.getData(CommonDataKeys.EDITOR) ?: return
        val lookup = LookupManager.getActiveLookup(editor) ?: return
        
        if (isNeoaiLookup(lookup)) {
            lookup.down()
        }
    }
    
    override fun update(e: AnActionEvent) {
        val editor = e.getData(CommonDataKeys.EDITOR)
        val lookup = editor?.let { LookupManager.getActiveLookup(it) }
        
        e.presentation.isEnabledAndVisible = lookup != null && isNeoaiLookup(lookup) && lookup.itemCount > 1
    }
    
    private fun isNeoaiLookup(lookup: Lookup): Boolean {
        return lookup.currentItem?.getUserData(InlineActionsPromoter.NEOAI_INLINE_COMPLETION_KEY) == true
    }
}
