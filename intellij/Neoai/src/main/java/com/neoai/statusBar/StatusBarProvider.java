package com.neoai.statusBar;

import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.wm.StatusBar;
import com.intellij.openapi.wm.StatusBarWidget;
import com.intellij.openapi.wm.StatusBarWidgetFactory;
import org.jetbrains.annotations.Nls;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Status bar widget factory for Neoai status indicator.
 */
public class StatusBarProvider implements StatusBarWidgetFactory {

    @NotNull
    @Override
    public String getId() {
        return "com.neoai.statusBar.StatusBarProvider";
    }

    @Nls(capitalization = Nls.Capitalization.Title)
    @NotNull
    @Override
    public String getDisplayName() {
        return "Neoai Status";
    }

    @Override
    public boolean isAvailable(@NotNull Project project) {
        return true;
    }

    @Nullable
    @Override
    public StatusBarWidget createWidget(@NotNull Project project) {
        return new NeoaiStatusBarWidget(project);
    }

    @Nullable
    @Override
    public Key<StatusBarWidget.WidgetState> getStateKey() {
        return null;
    }

    @Override
    public boolean canBeEnabled(@NotNull Project project) {
        return true;
    }
}
