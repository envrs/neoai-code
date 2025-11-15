import * as vscode from 'vscode';

export interface ExtensionEvent {
  type: string;
  data: any;
  timestamp: number;
}

export class EventManager {
  private static instance: EventManager;
  private listeners: Map<string, Array<(event: ExtensionEvent) => void>> = new Map();
  
  private constructor() {}
  
  public static getInstance(): EventManager {
    if (!EventManager.instance) {
      EventManager.instance = new EventManager();
    }
    return EventManager.instance;
  }
  
  public on(eventType: string, listener: (event: ExtensionEvent) => void): vscode.Disposable {
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, []);
    }
    this.listeners.get(eventType)!.push(listener);
    
    return new vscode.Disposable(() => {
      const listeners = this.listeners.get(eventType);
      if (listeners) {
        const index = listeners.indexOf(listener);
        if (index > -1) {
          listeners.splice(index, 1);
        }
      }
    });
  }
  
  public emit(eventType: string, data: any): void {
    const event: ExtensionEvent = {
      type: eventType,
      data,
      timestamp: Date.now()
    };
    
    const listeners = this.listeners.get(eventType);
    if (listeners) {
      listeners.forEach(listener => {
        try {
          listener(event);
        } catch (error) {
          console.error(`Error in event listener for ${eventType}:`, error);
        }
      });
    }
  }
  
  public off(eventType: string, listener: (event: ExtensionEvent) => void): void {
    const listeners = this.listeners.get(eventType);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }
}
