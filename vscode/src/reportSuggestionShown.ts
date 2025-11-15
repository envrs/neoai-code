import * as vscode from 'vscode';

export interface SuggestionReport {
  suggestion: string;
  accepted: boolean;
  timestamp: number;
  document: string;
  language: string;
}

export class SuggestionReporter {
  private static instance: SuggestionReporter;
  private reports: SuggestionReport[] = [];
  
  private constructor() {}
  
  public static getInstance(): SuggestionReporter {
    if (!SuggestionReporter.instance) {
      SuggestionReporter.instance = new SuggestionReporter();
    }
    return SuggestionReporter.instance;
  }
  
  public reportSuggestion(suggestion: string, accepted: boolean, document: vscode.TextDocument): void {
    const report: SuggestionReport = {
      suggestion,
      accepted,
      timestamp: Date.now(),
      document: document.fileName,
      language: document.languageId
    };
    
    this.reports.push(report);
    
    // TODO: Send to analytics service
    console.log('Suggestion reported:', report);
  }
  
  public getReports(): SuggestionReport[] {
    return [...this.reports];
  }
  
  public clearReports(): void {
    this.reports = [];
  }
}