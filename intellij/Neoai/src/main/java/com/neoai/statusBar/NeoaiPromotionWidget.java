package com.neoai.statusBar;

import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.wm.StatusBar;
import com.intellij.openapi.wm.StatusBarWidget;
import com.intellij.util.Consumer;
import com.neoai.general.BrowserUtilsService;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;
import java.awt.event.MouseEvent;

/**
 * Status bar widget for showing Neoai promotions and upgrade notifications.
 */
public class NeoaiPromotionWidget implements StatusBarWidget {

    private final Project project;
    private static final Key<NeoaiPromotionWidget> KEY = Key.create("NeoaiPromotionWidget");

    public NeoaiPromotionWidget(@NotNull Project project) {
        this.project = project;
    }

    @NotNull
    @Override
    public String ID() {
        return "NeoaiPromotionWidget";
    }

    @Nullable
    @Override
    public WidgetPresentation getPresentation() {
        return new WidgetPresentation() {
            @NotNull
            @Override
            public String getTooltipText() {
                return "Upgrade to Neoai Pro for advanced features";
            }

            @Nullable
            @Override
            public Consumer<MouseEvent> getClickConsumer() {
                return mouseEvent -> {
                    // Open pricing page when clicked
                    BrowserUtilsService.getInstance().openPricing();
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

    public static Key<NeoaiPromotionWidget> getKey() {
        return KEY;
    }
}
