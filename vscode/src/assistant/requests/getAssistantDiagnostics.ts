import * as vscode from 'vscode';
import { RequestHandler } from './request';

export interface DiagnosticRequest {
  document: vscode.TextDocument;
  language: string;
  content: string;
}

export interface DiagnosticResponse {
  diagnostics: Array<{
    line: number;
    character: number;
    message: string;
    severity: 'error' | 'warning' | 'info' | 'hint';
    source?: string;
  }>;
}

export async function getAssistantDiagnostics(request: DiagnosticRequest): Promise<DiagnosticResponse> {
  try {
    const response = await RequestHandler.makeVSCodeRequest({
      url: 'https://api.neoai.com/diagnostics',
      method: 'POST',
      body: {
        language: request.language,
        content: request.content,
        filename: request.document.fileName
      }
    });
    
    return response.data as DiagnosticResponse;
  } catch (error) {
    console.error('Failed to get assistant diagnostics:', error);
    return { diagnostics: [] };
  }
}