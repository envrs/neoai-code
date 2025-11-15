import * as vscode from 'vscode';
import { RequestHandler } from './request';

export interface CompilerDiagnosticRequest {
  document: vscode.TextDocument;
  compilerType: 'typescript' | 'javascript' | 'python' | 'java' | 'cpp' | 'c';
}

export interface CompilerDiagnosticResponse {
  diagnostics: Array<{
    line: number;
    character: number;
    endLine: number;
    endCharacter: number;
    message: string;
    severity: 'error' | 'warning' | 'info' | 'hint';
    code?: string;
    source: string;
  }>;
}

export async function getCompilerDiagnostics(request: CompilerDiagnosticRequest): Promise<CompilerDiagnosticResponse> {
  try {
    const response = await RequestHandler.makeVSCodeRequest({
      url: 'https://api.neoai.com/compiler-diagnostics',
      method: 'POST',
      body: {
        compilerType: request.compilerType,
        content: request.document.getText(),
        filename: request.document.fileName
      }
    });
    
    return response.data as CompilerDiagnosticResponse;
  } catch (error) {
    console.error('Failed to get compiler diagnostics:', error);
    return { diagnostics: [] };
  }
}