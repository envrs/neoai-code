import * as vscode from "vscode";

let neoaiExtensionContext: vscode.ExtensionContext | null = null;

export function setNeoaiExtensionContext(
  context: vscode.ExtensionContext
): void {
  neoaiExtensionContext = context;
}

export function getNeoaiExtensionContext(): vscode.ExtensionContext {
  if (!neoaiExtensionContext) {
    throw new Error("Extension context not set");
  }
  return neoaiExtensionContext;
}
