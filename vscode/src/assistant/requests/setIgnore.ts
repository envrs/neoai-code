import * as vscode from 'vscode';
import { RequestHandler } from './request';

export interface SetIgnoreRequest {
  pattern: string;
  isIgnored: boolean;
  scope?: 'global' | 'workspace' | 'file';
}

export interface SetIgnoreResponse {
  success: boolean;
  message: string;
}

export async function setIgnore(request: SetIgnoreRequest): Promise<SetIgnoreResponse> {
  try {
    const response = await RequestHandler.makeVSCodeRequest({
      url: 'https://api.neoai.com/ignore',
      method: 'POST',
      body: request
    });
    
    return response.data as SetIgnoreResponse;
  } catch (error) {
    console.error('Failed to set ignore:', error);
    vscode.window.showErrorMessage(`Failed to set ignore pattern: ${error}`);
    return { 
      success: false,
      message: 'Failed to set ignore pattern'
    };
  }
}