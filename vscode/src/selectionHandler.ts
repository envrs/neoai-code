import * as vscode from 'vscode';

export interface SelectionInfo {
  text: string;
  range: vscode.Range;
  document: vscode.TextDocument;
  language: string;
}

export class SelectionHandler {
  private static instance: SelectionHandler;
  
  private constructor() {}
  
  public static getInstance(): SelectionHandler {
    if (!SelectionHandler.instance) {
      SelectionHandler.instance = new SelectionHandler();
    }
    return SelectionHandler.instance;
  }
  
  public getSelection(): SelectionInfo | null {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      return null;
    }
    
    const selection = editor.selection;
    if (selection.isEmpty) {
      return null;
    }
    
    return {
      text: editor.document.getText(selection),
      range: new vscode.Range(selection.start, selection.end),
      document: editor.document,
      language: editor.document.languageId
    };
  }
  
  public getWordAtCursor(): SelectionInfo | null {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      return null;
    }
    
    const position = editor.selection.active;
    const wordRange = editor.document.getWordRangeAtPosition(position);
    
    if (!wordRange) {
      return null;
    }
    
    return {
      text: editor.document.getText(wordRange),
      range: wordRange,
      document: editor.document,
      language: editor.document.languageId
    };
  }
  
  public getLineAtCursor(): SelectionInfo | null {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      return null;
    }
    
    const position = editor.selection.active;
    const line = position.line;
    const lineRange = new vscode.Range(
      new vscode.Position(line, 0),
      new vscode.Position(line, editor.document.lineAt(line).text.length)
    );
    
    return {
      text: editor.document.getText(lineRange),
      range: lineRange,
      document: editor.document,
      language: editor.document.languageId
    };
  }
}