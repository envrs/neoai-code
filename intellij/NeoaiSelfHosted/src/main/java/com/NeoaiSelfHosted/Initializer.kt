package com.neoaiSelfHosted

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.application.PreloadingActivity
import com.intellij.openapi.components.ServiceManager
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.StartupActivity
import com.neoaiSelfHosted.chat.actions.AskChatAction
import com.neoaiSelfHosted.lifecycle.initializeLifecycleEndpoints
import com.neoaiSelfHosted.logging.initNeoaiLogger
import com.neoaiSelfHosted.notifications.ConnectionLostNotificationHandler
import com.neoaiSelfHosted.userSettings.AppSettingsState
import com.neoaiSelfHosted.binary.lifecycle.UserInfoService
import com.neoaiSelfHosted.chat.SelfHostedChatEnabledState
import com.neoaiSelfHosted.statusbar.NeoaiStatusBarManager
import java.util.concurrent.atomic.AtomicBoolean

class Initializer : PreloadingActivity(), StartupActivity {
    override fun preload(indicator: ProgressIndicator) {
        initialize()
    }

    override fun runActivity(project: Project) {
        initialize()
    }

    private fun initialize() {
        if (initialized.getAndSet(true) || ApplicationManager.getApplication().isUnitTestMode) {
            return
        }
        initNeoaiLogger()
        connectionLostNotificationHandler.startConnectionLostListener()
        val host = AppSettingsState.instance.cloud2Url
        SelfHostedInitializer().initialize(host) {
            AppSettingsState.instance.cloud2Url = it
        }
        AskChatAction.register {
            SelfHostedChatEnabledState.instance.get().enabled
        }
        initializeLifecycleEndpoints()
        ServiceManager.getService(UserInfoService::class.java).startUpdateLoop()
        
        // Initialize status bar manager
        NeoaiStatusBarManager.getInstance().initialize()
    }

    companion object {
        private val connectionLostNotificationHandler = ConnectionLostNotificationHandler()
        private val initialized = AtomicBoolean(false)
    }
}