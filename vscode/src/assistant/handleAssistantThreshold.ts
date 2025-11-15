import * as vscode from 'vscode';

export interface ThresholdConfig {
  maxFileSize: number;
  maxSelectionSize: number;
  maxResponseTime: number;
}

export const DEFAULT_THRESHOLD: ThresholdConfig = {
  maxFileSize: 1024 * 1024, // 1MB
  maxSelectionSize: 10000,   // 10KB
  maxResponseTime: 30000    // 30 seconds
};

export class AssistantThresholdHandler {
  private config: ThresholdConfig;
  
  constructor(config: Partial<ThresholdConfig> = {}) {
    this.config = { ...DEFAULT_THRESHOLD, ...config };
  }
  
  public checkFileSize(fileSize: number): boolean {
    return fileSize <= this.config.maxFileSize;
  }
  
  public checkSelectionSize(selectionSize: number): boolean {
    return selectionSize <= this.config.maxSelectionSize;
  }
  
  public async checkResponseTime<T>(
    operation: () => Promise<T>,
    timeout: number = this.config.maxResponseTime
  ): Promise<T> {
    return Promise.race([
      operation(),
      new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error('Operation timed out')), timeout);
      })
    ]);
  }
  
  public showThresholdWarning(type: 'file' | 'selection' | 'time'): void {
    const messages = {
      file: `File size exceeds limit (${this.config.maxFileSize / 1024 / 1024}MB)`,
      selection: `Selection size exceeds limit (${this.config.maxSelectionSize / 1024}KB)`,
      time: `Operation took too long (>${this.config.maxResponseTime / 1000}s)`
    };
    
    vscode.window.showWarningMessage(messages[type]);
  }
}