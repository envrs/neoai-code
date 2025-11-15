import * as vscode from 'vscode';

export interface RequestConfig {
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  headers?: Record<string, string>;
  body?: any;
  timeout?: number;
}

export interface ResponseData {
  status: number;
  data: any;
  headers: Record<string, string>;
}

export class RequestHandler {
  public static async makeRequest(config: RequestConfig): Promise<ResponseData> {
    const { url, method, headers = {}, body, timeout = 30000 } = config;
    
    return new Promise((resolve, reject) => {
      const request = require('request') || require('axios');
      
      const requestOptions: any = {
        url,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        },
        timeout,
        json: true
      };
      
      if (body && (method === 'POST' || method === 'PUT')) {
        requestOptions.body = body;
      }
      
      request(requestOptions, (error: any, response: any, responseBody: any) => {
        if (error) {
          reject(error);
          return;
        }
        
        resolve({
          status: response.statusCode,
          data: responseBody,
          headers: response.headers
        });
      });
    });
  }
  
  public static async makeVSCodeRequest(config: RequestConfig): Promise<ResponseData> {
    try {
      const response = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Making request...',
        cancellable: true
      }, async (progress, token) => {
        return this.makeRequest(config);
      });
      
      return response;
    } catch (error) {
      vscode.window.showErrorMessage(`Request failed: ${error}`);
      throw error;
    }
  }
}