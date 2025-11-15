import * as vscode from 'vscode';

export function acceptAssistantSelection(): void {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor');
    return;
  }
  
  // Get current selection
  const selection = editor.selection;
  const selectedText = editor.document.getText(selection);
  
  if (!selectedText) {
    vscode.window.showInformationMessage('No text selected to accept');
    return;
  }
  
  // Show confirmation dialog
  vscode.window.showInformationMessage(
    `Accept selection: "${selectedText.substring(0, 50)}${selectedText.length > 50 ? '...' : ''}"?`,
    'Accept', 'Cancel'
  ).then((choice) => {
    if (choice === 'Accept') {
      // Mark the selection as accepted (could be stored in state)
      vscode.window.showInformationMessage('Selection accepted');
    }
  });
}