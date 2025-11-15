import * as vscode from 'vscode';
import { spawn, ChildProcess } from 'child_process';
import { NeoAiCancellationToken } from './CancellationToken';

export interface AssistantProcessOptions {
  command: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  cancellationToken?: NeoAiCancellationToken;
}

export class AssistantProcess {
  private process: ChildProcess | null = null;
  private cancellationToken?: NeoAiCancellationToken;
  
  constructor(private options: AssistantProcessOptions) {
    this.cancellationToken = options.cancellationToken;
  }
  
  public async start(): Promise<void> {
    return new Promise((resolve, reject) => {
      const { command, args = [], cwd, env } = this.options;
      
      this.process = spawn(command, args, {
        cwd: cwd || vscode.workspace.rootPath,
        env: { ...process.env, ...env }
      });
      
      if (!this.process) {
        reject(new Error('Failed to start process'));
        return;
      }
      
      this.process.on('error', (error) => {
        reject(error);
      });
      
      this.process.on('spawn', () => {
        resolve();
      });
      
      this.process.on('exit', (code, signal) => {
        if (code !== 0) {
          console.warn(`Process exited with code ${code}, signal ${signal}`);
        }
        this.process = null;
      });
      
      // Handle cancellation
      if (this.cancellationToken) {
        const disposable = this.cancellationToken.onCancellationRequested(() => {
          this.kill();
          disposable.dispose();
        });
      }
    });
  }
  
  public async sendInput(data: string): Promise<void> {
    if (!this.process || !this.process.stdin) {
      throw new Error('Process not running or stdin not available');
    }
    
    return new Promise((resolve, reject) => {
      this.process!.stdin!.write(data, (error) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      });
    });
  }
  
  public async getOutput(): Promise<string> {
    return new Promise((resolve, reject) => {
      if (!this.process) {
        reject(new Error('Process not started'));
        return;
      }
      
      let output = '';
      
      if (this.process.stdout) {
        this.process.stdout.on('data', (data) => {
          output += data.toString();
        });
      }
      
      if (this.process.stderr) {
        this.process.stderr.on('data', (data) => {
          output += data.toString();
        });
      }
      
      this.process.on('exit', () => {
        resolve(output);
      });
      
      this.process.on('error', (error) => {
        reject(error);
      });
    });
  }
  
  public kill(): void {
    if (this.process) {
      this.process.kill();
      this.process = null;
    }
  }
  
  public isRunning(): boolean {
    return this.process !== null && !this.process.killed;
  }
  
  public dispose(): void {
    this.kill();
  }
}