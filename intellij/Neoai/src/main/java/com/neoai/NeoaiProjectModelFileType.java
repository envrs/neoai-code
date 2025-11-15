package com.neoai;

import com.intellij.openapi.fileTypes.Language;
import com.intellij.openapi.fileTypes.FileTypeConsumer;
import com.intellij.openapi.fileTypes.FileTypeFactory;
import com.intellij.openapi.util.NlsSafe;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

/**
 * File type for Neoai project model files.
 */
public class NeoaiProjectModelFileType implements com.intellij.openapi.fileTypes.FileType {

    public static final NeoaiProjectModelFileType INSTANCE = new NeoaiProjectModelFileType();
    
    @NotNull
    @Override
    public String getName() {
        return "Neoai Project Model";
    }

    @NlsSafe
    @NotNull
    @Override
    public String getDescription() {
        return "Neoai project model configuration file";
    }

    @NotNull
    @Override
    public String getDefaultExtension() {
        return "neoai";
    }

    @Nullable
    @Override
    public Icon getIcon() {
        return com.intellij.icons.AllIcons.FileTypes.Config;
    }

    @Override
    public boolean isBinary() {
        return false;
    }

    @Override
    public boolean isReadOnly() {
        return false;
    }

    @Nullable
    @Override
    public String getCharset(@NotNull byte[] content, @Nullable CharSequence chars) {
        return "UTF-8";
    }

    /**
     * Factory for registering the file type.
     */
    public static class Factory extends FileTypeFactory {
        @Override
        public void createFileTypes(@NotNull FileTypeConsumer consumer) {
            consumer.consume(NeoaiProjectModelFileType.INSTANCE, 
                           "neoai;.neoai;neoai.model;.neoai.model;model;.model");
        }
    }
}
