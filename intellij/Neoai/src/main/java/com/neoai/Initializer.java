package com.neoai;

import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.ApplicationComponent;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.startup.StartupActivity;
import org.jetbrains.annotations.NotNull;

/**
 * Main initializer for the Neoai plugin.
 * Handles plugin startup and initialization tasks.
 */
public class Initializer implements StartupActivity, ApplicationComponent {

    @Override
    public void runActivity(@NotNull Project project) {
        // Initialize plugin services and components
        initializePlugin(project);
    }

    @Override
    public void initComponent() {
        // Initialize application-level components
        initializeApplicationComponents();
    }

    @Override
    public void disposeComponent() {
        // Cleanup resources
    }

    @NotNull
    @Override
    public String getComponentName() {
        return "NeoaiInitializer";
    }

    private void initializePlugin(@NotNull Project project) {
        // Plugin initialization logic
        NeoaiServiceManager.getInstance().initializeForProject(project);
    }

    private void initializeApplicationComponents() {
        // Application-level initialization
        ApplicationManager.getApplication().getMessageBus().connect();
    }
}
