package com.neoaiCommon.lifecycle

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.util.xmlb.XmlSerializerUtil
import java.util.concurrent.atomic.AtomicBoolean

@State(name = "BinaryStateService", storages = [Storage("neoaiBinaryState.xml")])
@Service(Service.Level.APP)
class BinaryStateService : PersistentStateComponent<BinaryStateService.State>, LifecycleComponent {
    
    data class State(
        var binaryPath: String? = null,
        var binaryVersion: String? = null,
        var lastDownloadTime: Long = 0L,
        var autoUpdateEnabled: Boolean = true,
        var binaryStatus: BinaryStatus = BinaryStatus.NOT_DOWNLOADED
    )
    
    enum class BinaryStatus {
        NOT_DOWNLOADED,
        DOWNLOADING,
        DOWNLOADED,
        RUNNING,
        ERROR
    }
    
    private var state = State()
    private val initialized = AtomicBoolean(false)
    
    override fun getState(): State = state
    
    override fun loadState(state: State) {
        XmlSerializerUtil.copyBean(state, this.state)
    }
    
    override fun initialize() {
        if (initialized.getAndSet(true)) return
        // Initialize binary state
    }
    
    override fun isHealthy(): Boolean {
        return initialized.get()
    }
    
    override fun shutdown() {
        initialized.set(false)
    }
    
    fun getBinaryPath(): String? = state.binaryPath
    
    fun setBinaryPath(path: String?) {
        state.binaryPath = path
    }
    
    fun getBinaryVersion(): String? = state.binaryVersion
    
    fun setBinaryVersion(version: String?) {
        state.binaryVersion = version
    }
    
    fun getLastDownloadTime(): Long = state.lastDownloadTime
    
    fun setLastDownloadTime(time: Long) {
        state.lastDownloadTime = time
    }
    
    fun isAutoUpdateEnabled(): Boolean = state.autoUpdateEnabled
    
    fun setAutoUpdateEnabled(enabled: Boolean) {
        state.autoUpdateEnabled = enabled
    }
    
    fun getBinaryStatus(): BinaryStatus = state.binaryStatus
    
    fun setBinaryStatus(status: BinaryStatus) {
        state.binaryStatus = status
    }
    
    companion object {
        fun getInstance(): BinaryStateService = service()
    }
}
