package com.neoai.assistant.service;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonSyntaxException;
import com.intellij.openapi.application.ApplicationManager;
import com.intellij.openapi.components.Service;
import com.intellij.openapi.progress.ProgressIndicator;
import com.intellij.openapi.progress.ProgressManager;
import com.intellij.openapi.progress.Task;
import com.intellij.openapi.project.Project;
import com.intellij.util.ui.UIUtil;
import com.neoai.assistant.completion.CompletionContext;
import com.neoai.assistant.completion.NeoAICompletion;
import com.neoai.assistant.settings.NeoAISettings;
import okhttp3.*;
import org.jetbrains.annotations.NotNull;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Service for communicating with NeoAI API
 */
@Service
public final class NeoAIService {
    
    private final OkHttpClient httpClient;
    private final Gson gson;
    private final NeoAISettings settings;
    
    public NeoAIService() {
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();
            
        this.gson = new Gson();
        this.settings = ApplicationManager.getApplication().getService(NeoAISettings.class);
    }
    
    /**
     * Get AI completions for the given context
     */
    public List<NeoAICompletion> getCompletions(@NotNull CompletionContext context) {
        if (!settings.isEnabled() || !settings.hasValidApiToken()) {
            return new ArrayList<>();
        }
        
        try {
            // Prepare request
            JsonObject requestBody = createCompletionRequest(context);
            
            Request request = new Request.Builder()
                .url(settings.getApiUrl() + "/completions")
                .header("Authorization", "Bearer " + settings.getApiToken())
                .header("Content-Type", "application/json")
                .post(RequestBody.create(
                    requestBody.toString(),
                    MediaType.parse("application/json")
                ))
                .build();
            
            // Execute request
            try (Response response = httpClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    System.err.println("API request failed: " + response.code() + " " + response.message());
                    return new ArrayList<>();
                }
                
                String responseBody = response.body().string();
                return parseCompletionResponse(responseBody);
            }
            
        } catch (Exception e) {
            System.err.println("Error getting completions: " + e.getMessage());
            return new ArrayList<>();
        }
    }
    
    /**
     * Get completions asynchronously
     */
    public CompletableFuture<List<NeoAICompletion>> getCompletionsAsync(@NotNull CompletionContext context) {
        return CompletableFuture.supplyAsync(() -> getCompletions(context));
    }
    
    /**
     * Generate code with AI
     */
    public String generateCode(@NotNull Project project, @NotNull String prompt) {
        if (!settings.isEnabled() || !settings.hasValidApiToken()) {
            return "AI service is not enabled or configured properly.";
        }
        
        try {
            JsonObject requestBody = new JsonObject();
            requestBody.addProperty("prompt", prompt);
            requestBody.addProperty("max_tokens", settings.getMaxTokens());
            requestBody.addProperty("temperature", settings.getTemperature());
            requestBody.addProperty("model", settings.getModel());
            
            Request request = new Request.Builder()
                .url(settings.getApiUrl() + "/generate")
                .header("Authorization", "Bearer " + settings.getApiToken())
                .header("Content-Type", "application/json")
                .post(RequestBody.create(
                    requestBody.toString(),
                    MediaType.parse("application/json")
                ))
                .build();
            
            try (Response response = httpClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    return "API request failed: " + response.code() + " " + response.message();
                }
                
                String responseBody = response.body().string();
                JsonObject responseJson = gson.fromJson(responseBody, JsonObject.class);
                
                if (responseJson.has("text")) {
                    return responseJson.get("text").getAsString();
                } else {
                    return "No response from AI service.";
                }
            }
            
        } catch (Exception e) {
            return "Error generating code: " + e.getMessage();
        }
    }
    
    /**
     * Explain code with AI
     */
    public String explainCode(@NotNull String code, @NotNull String language) {
        if (!settings.isEnabled() || !settings.hasValidApiToken()) {
            return "AI service is not enabled or configured properly.";
        }
        
        String prompt = String.format(
            "Explain this %s code:\n\n```%s\n%s\n```",
            language, language, code
        );
        
        return generateCode(null, prompt);
    }
    
    /**
     * Called when a completion is accepted by the user
     */
    public void onCompletionAccepted(@NotNull NeoAICompletion completion) {
        // Send analytics or feedback to API
        if (settings.isTelemetryEnabled()) {
            CompletableFuture.runAsync(() -> {
                try {
                    JsonObject feedback = new JsonObject();
                    feedback.addProperty("completion_text", completion.getText());
                    feedback.addProperty("completion_type", completion.getType());
                    feedback.addProperty("confidence", completion.getConfidence());
                    
                    Request request = new Request.Builder()
                        .url(settings.getApiUrl() + "/feedback")
                        .header("Authorization", "Bearer " + settings.getApiToken())
                        .header("Content-Type", "application/json")
                        .post(RequestBody.create(
                            feedback.toString(),
                            MediaType.parse("application/json")
                        ))
                        .build();
                    
                    httpClient.newCall(request).execute();
                } catch (Exception e) {
                    // Silently ignore feedback errors
                }
            });
        }
    }
    
    private JsonObject createCompletionRequest(@NotNull CompletionContext context) {
        JsonObject request = new JsonObject();
        
        request.addProperty("prefix", context.getPrefix());
        request.addProperty("current_line", context.getCurrentLine());
        request.addProperty("file_content", context.getFileContent());
        request.addProperty("language", context.getLanguage());
        request.addProperty("offset", context.getOffset());
        request.addProperty("line_number", context.getLineNumber());
        request.addProperty("file_path", context.getFilePath());
        request.addProperty("context_window", context.getContextWindow(10, 5));
        request.addProperty("max_tokens", settings.getMaxTokens());
        request.addProperty("temperature", settings.getTemperature());
        request.addProperty("model", settings.getModel());
        
        return request;
    }
    
    private List<NeoAICompletion> parseCompletionResponse(@NotNull String responseBody) {
        try {
            JsonObject response = gson.fromJson(responseBody, JsonObject.class);
            
            if (!response.has("completions")) {
                return new ArrayList<>();
            }
            
            List<NeoAICompletion> completions = new ArrayList<>();
            // Parse completions from response
            // This would depend on the actual API response format
            
            return completions;
            
        } catch (JsonSyntaxException e) {
            System.err.println("Failed to parse API response: " + e.getMessage());
            return new ArrayList<>();
        }
    }
}
