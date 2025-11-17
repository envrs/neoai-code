package com.neoai;

import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.Service;
import com.intellij.openapi.project.Project;
import org.jetbrains.annotations.NotNull;

/**
 * Central service manager for Neoai plugin services.
 */
@Service
public final class NeoaiServiceManager {
    
    private static NeoaiServiceManager instance;
    
    public NeoaiServiceManager() {
        instance = this;
    }
    
    public static NeoaiServiceManager getInstance() {
        if (instance == null) {
            instance = ApplicationManager.getApplication().getService(NeoaiServiceManager.class);
        }
        return instance;
    }
    
    public void initializeForProject(@NotNull Project project) {
        // Initialize project-specific services
        // This will be implemented as we add more services
    }
}
