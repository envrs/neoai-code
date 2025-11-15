import * as vscode from 'vscode';
import { AssistantDiagnostic } from './AssistantDiagnostic';

export class DiagnosticsManager {
  private diagnostic: AssistantDiagnostic;
  private static instance: DiagnosticsManager;
  
  private constructor() {
    this.diagnostic = new AssistantDiagnostic();
  }
  
  public static getInstance(): DiagnosticsManager {
    if (!DiagnosticsManager.instance) {
      DiagnosticsManager.instance = new DiagnosticsManager();
    }
    return DiagnosticsManager.instance;
  }
  
  public updateDiagnostics(document: vscode.TextDocument, items: any[]): void {
    this.diagnostic.setDiagnostics(document.uri, items);
  }
  
  public clearDiagnostics(document?: vscode.TextDocument): void {
    if (document) {
      this.diagnostic.clearDiagnostics(document.uri);
    } else {
      this.diagnostic.clearDiagnostics();
    }
  }
  
  public dispose(): void {
    this.diagnostic.dispose();
  }
}