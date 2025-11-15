package com.neoaiCommon.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.StartupActivity
import com.intellij.util.messages.Topic
import java.util.concurrent.atomic.AtomicBoolean

@Service(Service.Level.APP)
class LifeCycleHelper : StartupActivity.DumbAware {
    
    private val initialized = AtomicBoolean(false)
    
    override fun runActivity(project: Project) {
        if (initialized.getAndSet(true)) {
            return
        }
        
        val messageBus = ApplicationManager.getApplication().messageBus
        messageBus.syncPublisher(LifecycleListener.TOPIC).onApplicationStarted()
        
        BinaryStateService.getInstance()
        CapabilitiesService.getInstance()
    }
    
    fun shutdown() {
        if (!initialized.get()) return
        
        val messageBus = ApplicationManager.getApplication().messageBus
        messageBus.syncPublisher(LifecycleListener.TOPIC).onApplicationShutdown()
        initialized.set(false)
    }
    
    interface LifecycleListener {
        companion object {
            val TOPIC = Topic.create("Neoai Lifecycle", LifecycleListener::class.java)
        }
        
        fun onApplicationStarted() {}
        fun onApplicationShutdown() {}
    }
    
    companion object {
        fun getInstance(): LifeCycleHelper = service()
    }
}
