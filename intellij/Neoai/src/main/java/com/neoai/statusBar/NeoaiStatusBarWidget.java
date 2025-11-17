package com.neoai.statusBar;

import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.wm.StatusBar;
import com.intellij.openapi.wm.StatusBarWidget;
import com.intellij.util.Consumer;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

/**
 * Neoai status bar widget implementation.
 */
public class NeoaiStatusBarWidget implements StatusBarWidget {

    private final Project project;
    private static final Key<NeoaiStatusBarWidget> KEY = Key.create("NeoaiStatusBarWidget");

    public NeoaiStatusBarWidget(@NotNull Project project) {
        this.project = project;
    }

    @NotNull
    @Override
    public String ID() {
        return "NeoaiStatusBarWidget";
    }

    @Nullable
    @Override
    public WidgetPresentation getPresentation() {
        return new WidgetPresentation() {
            @NotNull
            @Override
            public String getTooltipText() {
                return "Neoai AI Assistant Status";
            }

            @Nullable
            @Override
            public Consumer<MouseEvent> getClickConsumer() {
                return mouseEvent -> {
                    // Handle click on status bar widget
                    // Could open settings or chat window
                };
            }
        };
    }

    @Override
    public void install(@NotNull StatusBar statusBar) {
        // Install widget into status bar
    }

    @Override
    public void dispose() {
        // Cleanup resources
    }

    public static Key<NeoaiStatusBarWidget> getKey() {
        return KEY;
    }
}
