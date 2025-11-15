import * as vscode from 'vscode';
import { AssistantClient } from './AssistantClient';
import { DocumentValidator } from './DocumentValidator';
import { AssistantThresholdHandler } from './handleAssistantThreshold';

export async function runAssistant(): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor');
    return;
  }
  
  const document = editor.document;
  const selection = editor.selection;
  
  // Validate document
  const documentValidation = DocumentValidator.validateDocument(document);
  if (!documentValidation.isValid) {
    vscode.window.showErrorMessage(`Document validation failed: ${documentValidation.errors.join(', ')}`);
    return;
  }
  
  // Validate selection
  const selectionValidation = DocumentValidator.validateSelection(document, selection);
  if (!selectionValidation.isValid) {
    vscode.window.showErrorMessage(`Selection validation failed: ${selectionValidation.errors.join(', ')}`);
    return;
  }
  
  // Check thresholds
  const thresholdHandler = new AssistantThresholdHandler();
  const selectedText = document.getText(selection);
  
  if (!thresholdHandler.checkSelectionSize(selectedText.length)) {
    thresholdHandler.showThresholdWarning('selection');
    return;
  }
  
  try {
    const client = AssistantClient.getInstance();
    
    await vscode.window.withProgress({
      location: vscode.ProgressLocation.Notification,
      title: 'NeoAI Assistant',
      cancellable: true
    }, async (progress, token) => {
      progress.report({ increment: 0, message: 'Processing request...' });
      
      const response = await thresholdHandler.checkResponseTime(
        () => client.requestCompletion({
          prompt: selectedText,
          mode: {} as any, // Will be properly implemented
          cancellationToken: token as any
        })
      );
      
      progress.report({ increment: 100, message: 'Complete!' });
      
      // Handle response
      if (response.suggestions.length > 0) {
        await editor.edit(editBuilder => {
          editBuilder.replace(selection, response.suggestions[0]);
        });
        vscode.window.showInformationMessage('Assistant completed successfully');
      } else {
        vscode.window.showInformationMessage('No suggestions available');
      }
    });
  } catch (error) {
    vscode.window.showErrorMessage(`Assistant error: ${error}`);
  }
}