package com.neoai.assistant.completion;

/**
 * Context for AI completion requests
 */
public class CompletionContext {
    
    private final String prefix;
    private final String currentLine;
    private final String fileContent;
    private final String language;
    private final int offset;
    private final int lineNumber;
    private final String filePath;
    
    public CompletionContext(String prefix, String currentLine, String fileContent,
                           String language, int offset, int lineNumber, String filePath) {
        this.prefix = prefix;
        this.currentLine = currentLine;
        this.fileContent = fileContent;
        this.language = language;
        this.offset = offset;
        this.lineNumber = lineNumber;
        this.filePath = filePath;
    }
    
    public String getPrefix() {
        return prefix;
    }
    
    public String getCurrentLine() {
        return currentLine;
    }
    
    public String getFileContent() {
        return fileContent;
    }
    
    public String getLanguage() {
        return language;
    }
    
    public int getOffset() {
        return offset;
    }
    
    public int getLineNumber() {
        return lineNumber;
    }
    
    public String getFilePath() {
        return filePath;
    }
    
    /**
     * Get context around the cursor (few lines before and after)
     */
    public String getContextWindow(int linesBefore, int linesAfter) {
        String[] lines = fileContent.split("\n");
        int startLine = Math.max(0, lineNumber - linesBefore);
        int endLine = Math.min(lines.length - 1, lineNumber + linesAfter);
        
        StringBuilder context = new StringBuilder();
        for (int i = startLine; i <= endLine; i++) {
            context.append(lines[i]);
            if (i < endLine) {
                context.append("\n");
            }
        }
        
        return context.toString();
    }
    
    /**
     * Get the current line up to the cursor
     */
    public String getLinePrefix() {
        int lineStart = fileContent.lastIndexOf('\n', offset - 1) + 1;
        return fileContent.substring(lineStart, offset);
    }
    
    /**
     * Get the current line after the cursor
     */
    public String getLineSuffix() {
        int lineEnd = fileContent.indexOf('\n', offset);
        if (lineEnd == -1) {
            lineEnd = fileContent.length();
        }
        return fileContent.substring(offset, lineEnd);
    }
}
