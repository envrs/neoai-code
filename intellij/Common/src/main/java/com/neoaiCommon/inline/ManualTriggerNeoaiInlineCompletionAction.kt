package com.neoaiCommon.inline

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.project.Project

class ManualTriggerNeoaiInlineCompletionAction : AnAction() {
    
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return
        val editor = e.getData(CommonDataKeys.EDITOR) ?: return
        val document = editor.document
        
        val manager = InlineCompletionManager.getInstance(project)
        manager.triggerCompletion(document)
    }
    
    override fun update(e: AnActionEvent) {
        val project = e.project
        val editor = e.getData(CommonDataKeys.EDITOR)
        val settings = com.neoaiCommon.userSettings.AppSettingsState.getInstance()
        
        e.presentation.isEnabledAndVisible = project != null && 
            editor != null && 
            settings.isEnabled() && 
            com.neoaiCommon.capabilities.CapabilitiesService.getInstance().isInlineCompletionEnabled()
    }
}
