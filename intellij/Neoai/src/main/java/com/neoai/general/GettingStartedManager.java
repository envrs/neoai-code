package com.neoai.general;

import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.PersistentStateComponent;
import com.intellij.openapi.components.State;
import com.intellij.openapi.components.Storage;
import com.intellij.openapi.project.Project;
import com.intellij.util.xmlb.XmlSerializerUtil;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/**
 * Manages getting started experience for Neoai plugin.
 */
@State(
    name = "NeoaiGettingStartedManager",
    storages = @Storage("NeoaiGettingStarted.xml")
)
public class GettingStartedManager implements PersistentStateComponent<GettingStartedManager.State> {

    public static class State {
        public boolean hasSeenWelcome = false;
        public boolean hasCompletedTutorial = false;
        public boolean showTips = true;
    }

    private State state = new State();

    public static GettingStartedManager getInstance() {
        return ApplicationManager.getApplication().getService(GettingStartedManager.class);
    }

    @Nullable
    @Override
    public State getState() {
        return state;
    }

    @Override
    public void loadState(@NotNull State state) {
        XmlSerializerUtil.copyBean(state, this.state);
    }

    public void showWelcomeIfNeeded(@NotNull Project project) {
        if (!state.hasSeenWelcome) {
            showWelcomeDialog(project);
            state.hasSeenWelcome = true;
        }
    }

    public void showTutorialIfNeeded(@NotNull Project project) {
        if (!state.hasCompletedTutorial) {
            showTutorialDialog(project);
        }
    }

    private void showWelcomeDialog(@NotNull Project project) {
        // Show welcome dialog
        // This would display introduction to Neoai features
    }

    private void showTutorialDialog(@NotNull Project project) {
        // Show interactive tutorial
        // This would guide users through basic features
    }

    public boolean shouldShowTips() {
        return state.showTips;
    }

    public void setTipsEnabled(boolean enabled) {
        state.showTips = enabled;
    }
}
