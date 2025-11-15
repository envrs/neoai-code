import * as vscode from 'vscode';
import { AssistantClient } from './AssistantClient';

export class AssistantCodeActionProvider implements vscode.CodeActionProvider {
  private static readonly providedCodeActionKinds = [
    vscode.CodeActionKind.QuickFix,
    vscode.CodeActionKind.Refactor,
    vscode.CodeActionKind.RefactorRewrite
  ];

  public static readonly metadata: vscode.CodeActionProviderMetadata = {
    providedCodeActionKinds: AssistantCodeActionProvider.providedCodeActionKinds
  };

  public provideCodeActions(
    document: vscode.TextDocument,
    range: vscode.Range | vscode.Selection,
    context: vscode.CodeActionContext,
    token: vscode.CancellationToken
  ): vscode.CodeAction[] {
    const actions: vscode.CodeAction[] = [];
    
    // Only provide actions for diagnostics with our source
    const relevantDiagnostics = context.diagnostics.filter(d => d.source === 'neoai-assistant');
    
    if (relevantDiagnostics.length === 0) {
      return actions;
    }
    
    // Create quick fix action
    const quickFixAction = new vscode.CodeAction(
      'NeoAI Quick Fix',
      vscode.CodeActionKind.QuickFix
    );
    quickFixAction.command = {
      command: 'neoai.assistant.quickFix',
      title: 'Apply NeoAI Quick Fix',
      arguments: [document, range]
    };
    actions.push(quickFixAction);
    
    // Create refactor action
    const refactorAction = new vscode.CodeAction(
      'NeoAI Refactor',
      vscode.CodeActionKind.RefactorRewrite
    );
    refactorAction.command = {
      command: 'neoai.assistant.refactor',
      title: 'Refactor with NeoAI',
      arguments: [document, range]
    };
    actions.push(refactorAction);
    
    // Create explain action
    const explainAction = new vscode.CodeAction(
      'NeoAI Explain',
      vscode.CodeActionKind.QuickFix
    );
    explainAction.command = {
      command: 'neoai.assistant.explain',
      title: 'Explain with NeoAI',
      arguments: [document, range]
    };
    actions.push(explainAction);
    
    return actions;
  }
  
  public resolveCodeAction(
    codeAction: vscode.CodeAction,
    token: vscode.CancellationToken
  ): vscode.CodeAction {
    // Resolve additional details for code action
    return codeAction;
  }
}