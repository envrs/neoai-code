package com.neoai.general;

import com.intellij.ide.BrowserUtil;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.Service;
import org.jetbrains.annotations.NotNull;

/**
 * Service for handling browser-related operations in Neoai plugin.
 */
@Service
public final class BrowserUtilsService {

    public static BrowserUtilsService getInstance() {
        return ApplicationManager.getApplication().getService(BrowserUtilsService.class);
    }

    /**
     * Opens a URL in the system default browser.
     */
    public void openUrl(@NotNull String url) {
        BrowserUtil.browse(url);
    }

    /**
     * Opens Neoai documentation.
     */
    public void openDocumentation() {
        openUrl("https://www.neoai.com/docs");
    }

    /**
     * Opens Neoai support page.
     */
    public void openSupport() {
        openUrl("https://www.neoai.com/support");
    }

    /**
     * Opens Neoai pricing page.
     */
    public void openPricing() {
        openUrl("https://www.neoai.com/pricing");
    }

    /**
     * Opens Neoai FAQ.
     */
    public void openFAQ() {
        openUrl("https://www.neoai.com/faq");
    }
}
