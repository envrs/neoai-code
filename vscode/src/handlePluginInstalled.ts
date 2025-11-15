import * as vscode from 'vscode';

export function handlePluginInstalled(): void {
  vscode.window.showInformationMessage('NeoAI plugin installed successfully!');
  
  // Show welcome message
  vscode.window.showInformationMessage(
    'Welcome to NeoAI! Get started by selecting some code and using the NeoAI commands.',
    'View Commands',
    'Dismiss'
  ).then((choice: string | undefined) => {
    if (choice === 'View Commands') {
      vscode.commands.executeCommand('workbench.action.showCommands');
    }
  });
}