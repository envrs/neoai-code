import * as vscode from 'vscode';

export function ignoreAssistantSelection(): void {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showErrorMessage('No active editor');
    return;
  }
  
  // Get current selection
  const selection = editor.selection;
  const selectedText = editor.document.getText(selection);
  
  if (!selectedText) {
    vscode.window.showInformationMessage('No text selected to ignore');
    return;
  }
  
  // Show confirmation dialog
  vscode.window.showInformationMessage(
    `Ignore selection: "${selectedText.substring(0, 50)}${selectedText.length > 50 ? '...' : ''}"?`,
    'Ignore', 'Cancel'
  ).then((choice: string | undefined) => {
    if (choice === 'Ignore') {
      // Mark the selection as ignored (could be stored in state)
      vscode.window.showInformationMessage('Selection ignored');
    }
  });
}