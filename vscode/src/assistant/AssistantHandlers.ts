import * as vscode from 'vscode';
import { AssistantClient } from './AssistantClient';

export class AssistantHandlers {
  private client: AssistantClient;
  
  constructor(client: AssistantClient) {
    this.client = client;
  }
  
  public registerCompletionHandler(): vscode.Disposable {
    return vscode.commands.registerCommand('neoai.assistant.complete', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        vscode.window.showErrorMessage('No active editor');
        return;
      }
      
      try {
        const selection = editor.selection;
        const text = editor.document.getText(selection);
        
        if (!text) {
          vscode.window.showInformationMessage('Please select some text to complete');
          return;
        }
        
        // Show progress indicator
        await vscode.window.withProgress({
          location: vscode.ProgressLocation.Notification,
          title: 'NeoAI Assistant',
          cancellable: true
        }, async (progress, token) => {
          progress.report({ increment: 0, message: 'Generating completion...' });
          
          // Request completion from assistant
          const response = await this.client.requestCompletion({
            prompt: text,
            mode: {} as any, // Will be properly implemented
            cancellationToken: token as any
          });
          
          progress.report({ increment: 100, message: 'Complete!' });
          
          // Insert completion
          if (response.suggestions.length > 0) {
            await editor.edit(editBuilder => {
              editBuilder.insert(selection.end, response.suggestions[0]);
            });
          }
        });
      } catch (error) {
        vscode.window.showErrorMessage(`Assistant error: ${error}`);
      }
    });
  }
  
  public registerDiagnosticHandler(): vscode.Disposable {
    return vscode.commands.registerCommand('neoai.assistant.diagnose', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        vscode.window.showErrorMessage('No active editor');
        return;
      }
      
      try {
        const diagnostics = await this.client.requestDiagnostics(editor.document);
        
        // Clear existing diagnostics
        const diagnosticCollection = vscode.languages.createDiagnosticCollection('neoai');
        diagnosticCollection.clear();
        
        // Add new diagnostics
        const diagnosticArray: vscode.Diagnostic[] = diagnostics.map(d => {
          const range = new vscode.Range(
            d.line || 0,
            d.character || 0,
            d.line || 0,
            d.character || 0
          );
          return new vscode.Diagnostic(
            range,
            d.message || 'Unknown error',
            this.getDiagnosticSeverity(d.severity)
          );
        });
        
        diagnosticCollection.set(editor.document.uri, diagnosticArray);
      } catch (error) {
        vscode.window.showErrorMessage(`Diagnostic error: ${error}`);
      }
    });
  }
  
  private getDiagnosticSeverity(severity?: string): vscode.DiagnosticSeverity {
    switch (severity) {
      case 'error': return vscode.DiagnosticSeverity.Error;
      case 'warning': return vscode.DiagnosticSeverity.Warning;
      case 'info': return vscode.DiagnosticSeverity.Information;
      default: return vscode.DiagnosticSeverity.Hint;
    }
  }
  
  public dispose(): void {
    this.client.dispose();
  }
}