import * as vscode from 'vscode';

export function handleUninstall(): void {
  // Clean up any resources
  const disposables: vscode.Disposable[] = [];
  
  // Dispose all registered disposables
  disposables.forEach(disposable => disposable.dispose());
  
  // Clear any cached data
  vscode.workspace.getConfiguration('neoai').update('enabled', false, vscode.ConfigurationTarget.Global);
  
  console.log('NeoAI extension uninstalled');
}