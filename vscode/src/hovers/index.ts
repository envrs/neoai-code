import * as vscode from 'vscode';
import { HoverProvider } from './HoverProvider';

export function registerHoverProviders(context: vscode.ExtensionContext): vscode.Disposable[] {
  const disposables: vscode.Disposable[] = [];
  
  // Register hover provider for supported languages
  const hoverProvider = new HoverProvider();
  const supportedLanguages = ['typescript', 'javascript', 'python', 'java', 'cpp', 'c'];
  
  supportedLanguages.forEach(language => {
    const disposable = vscode.languages.registerHoverProvider(language, hoverProvider);
    disposables.push(disposable);
  });
  
  return disposables;
}
