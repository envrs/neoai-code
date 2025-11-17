package com.neoaiCommon.inline

import com.intellij.codeInsight.lookup.LookupElement
import com.intellij.codeInsight.lookup.LookupElementAction
import com.intellij.codeInsight.lookup.LookupElementPromoter
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent

class InlineActionsPromoter : LookupElementPromoter {
    
    override fun promoteElement(lookupElement: LookupElement): Boolean {
        return lookupElement.getUserData(NEOAI_INLINE_COMPLETION_KEY) != null
    }
    
    companion object {
        val NEOAI_INLINE_COMPLETION_KEY = com.intellij.openapi.util.Key.create<Boolean>("neoai.inline.completion")
    }
}
