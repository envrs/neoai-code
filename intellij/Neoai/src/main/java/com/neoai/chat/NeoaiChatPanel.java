package com.neoai.chat;

import com.intellij.openapi.project.Project;
import com.intellij.ui.components.JBScrollPane;
import com.intellij.ui.components.JBTextArea;
import com.intellij.util.ui.FormBuilder;
import org.jetbrains.annotations.NotNull;

import javax.swing.*;
import java.awt.*;

/**
 * Main chat panel for Neoai Chat functionality.
 */
public class NeoaiChatPanel extends JPanel {

    private final Project project;
    private JBTextArea chatHistory;
    private JBTextArea inputArea;
    private JButton sendButton;

    public NeoaiChatPanel(@NotNull Project project) {
        this.project = project;
        initializeComponents();
        layoutComponents();
    }

    private void initializeComponents() {
        chatHistory = new JBTextArea();
        chatHistory.setEditable(false);
        chatHistory.setRows(20);
        chatHistory.setColumns(50);
        chatHistory.setText("Neoai Chat - Ask me anything about your code!\n\n");

        inputArea = new JBTextArea();
        inputArea.setRows(3);
        inputArea.setColumns(50);
        inputArea.setLineWrap(true);
        inputArea.setWrapStyleWord(true);

        sendButton = new JButton("Send");
        sendButton.addActionListener(e -> sendMessage());
    }

    private void layoutComponents() {
        setLayout(new BorderLayout());
        
        JBScrollPane historyScrollPane = new JBScrollPane(chatHistory);
        JBScrollPane inputScrollPane = new JBScrollPane(inputArea);
        
        JPanel inputPanel = new JPanel(new BorderLayout());
        inputPanel.add(inputScrollPane, BorderLayout.CENTER);
        inputPanel.add(sendButton, BorderLayout.EAST);

        add(historyScrollPane, BorderLayout.CENTER);
        add(inputPanel, BorderLayout.SOUTH);
    }

    private void sendMessage() {
        String message = inputArea.getText().trim();
        if (message.isEmpty()) {
            return;
        }

        // Add user message to chat
        chatHistory.append("You: " + message + "\n");
        
        // Clear input
        inputArea.setText("");
        
        // Process message (placeholder for AI response)
        processMessage(message);
    }

    private void processMessage(@NotNull String message) {
        // Placeholder for AI processing
        // This would integrate with the Neoai AI service
        String response = "AI response to: " + message;
        chatHistory.append("Neoai: " + response + "\n\n");
    }
}
