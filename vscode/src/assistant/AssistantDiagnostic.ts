import * as vscode from 'vscode';

export interface AssistantDiagnosticItem {
  line: number;
  character: number;
  message: string;
  severity: 'error' | 'warning' | 'info' | 'hint';
  source?: string;
  code?: string;
}

export class AssistantDiagnostic {
  private diagnosticCollection: vscode.DiagnosticCollection;
  
  constructor() {
    this.diagnosticCollection = vscode.languages.createDiagnosticCollection('neoai-assistant');
  }
  
  public setDiagnostics(uri: vscode.Uri, diagnostics: AssistantDiagnosticItem[]): void {
    const vscodeDiagnostics = diagnostics.map(item => this.convertToVscodeDiagnostic(item));
    this.diagnosticCollection.set(uri, vscodeDiagnostics);
  }
  
  public clearDiagnostics(uri?: vscode.Uri): void {
    if (uri) {
      this.diagnosticCollection.delete(uri);
    } else {
      this.diagnosticCollection.clear();
    }
  }
  
  public getDiagnostics(uri: vscode.Uri): vscode.Diagnostic[] {
    return this.diagnosticCollection.get(uri) || [];
  }
  
  private convertToVscodeDiagnostic(item: AssistantDiagnosticItem): vscode.Diagnostic {
    const range = new vscode.Range(
      item.line,
      item.character,
      item.line,
      item.character + 1
    );
    
    const severity = this.convertSeverity(item.severity);
    
    const diagnostic = new vscode.Diagnostic(range, item.message, severity);
    
    if (item.source) {
      diagnostic.source = item.source;
    }
    
    if (item.code) {
      diagnostic.code = item.code;
    }
    
    return diagnostic;
  }
  
  private convertSeverity(severity: string): vscode.DiagnosticSeverity {
    switch (severity) {
      case 'error': return vscode.DiagnosticSeverity.Error;
      case 'warning': return vscode.DiagnosticSeverity.Warning;
      case 'info': return vscode.DiagnosticSeverity.Information;
      case 'hint': return vscode.DiagnosticSeverity.Hint;
      default: return vscode.DiagnosticSeverity.Information;
    }
  }
  
  public dispose(): void {
    this.diagnosticCollection.dispose();
  }
}