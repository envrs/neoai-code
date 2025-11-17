package com.neoai.assistant.completion;

import com.intellij.openapi.editor.markup.TextAttributes;
import com.intellij.ui.JBColor;
import com.intellij.util.ui.UIUtil;

import javax.swing.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents an AI-generated completion
 */
public class NeoAICompletion {
    
    private final String text;
    private final String type;
    private final String detail;
    private final String documentation;
    private final List<TextEdit> additionalTextEdits;
    private final double confidence;
    
    public NeoAICompletion(String text) {
        this(text, "text", "", "", new ArrayList<>(), 1.0);
    }
    
    public NeoAICompletion(String text, String type, String detail, 
                          String documentation, List<TextEdit> additionalTextEdits,
                          double confidence) {
        this.text = text;
        this.type = type;
        this.detail = detail;
        this.documentation = documentation;
        this.additionalTextEdits = additionalTextEdits;
        this.confidence = confidence;
    }
    
    public String getText() {
        return text;
    }
    
    public String getType() {
        return type;
    }
    
    public String getDetail() {
        return detail;
    }
    
    public String getDocumentation() {
        return documentation;
    }
    
    public List<TextEdit> getAdditionalTextEdits() {
        return additionalTextEdits;
    }
    
    public boolean hasAdditionalTextEdits() {
        return !additionalTextEdits.isEmpty();
    }
    
    public double getConfidence() {
        return confidence;
    }
    
    public Icon getIcon() {
        // Return different icons based on completion type
        switch (type.toLowerCase()) {
            case "function":
                return UIUtil.getTreeNodeIcon(false);
            case "variable":
                return UIUtil.getTreeNodeIcon(true);
            case "class":
                return UIUtil.getClassIcon();
            case "interface":
                return UIUtil.getInterfaceIcon();
            default:
                return UIUtil.getTreeNodeIcon(false);
        }
    }
    
    /**
     * Text edit for additional modifications
     */
    public static class TextEdit {
        private final int startOffset;
        private final int endOffset;
        private final String text;
        
        public TextEdit(int startOffset, int endOffset, String text) {
            this.startOffset = startOffset;
            this.endOffset = endOffset;
            this.text = text;
        }
        
        public int getStartOffset() {
            return startOffset;
        }
        
        public int getEndOffset() {
            return endOffset;
        }
        
        public String getText() {
            return text;
        }
    }
}
