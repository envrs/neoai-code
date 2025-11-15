import * as vscode from 'vscode';
import { InlineSuggestionProvider } from './InlineSuggestionProvider';

export function registerInlineSuggestionProviders(context: vscode.ExtensionContext): vscode.Disposable[] {
  const disposables: vscode.Disposable[] = [];
  
  // Register inline suggestion provider for supported languages
  const provider = new InlineSuggestionProvider();
  const supportedLanguages = ['typescript', 'javascript', 'python', 'java', 'cpp', 'c'];
  
  supportedLanguages.forEach(language => {
    const disposable = vscode.languages.registerInlineCompletionItemProvider(language, provider);
    disposables.push(disposable);
  });
  
  return disposables;
}
