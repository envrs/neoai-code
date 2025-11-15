import * as vscode from 'vscode';

export class HoverProvider implements vscode.HoverProvider {
  public provideHover(
    document: vscode.TextDocument,
    position: vscode.Position,
    token: vscode.CancellationToken
  ): vscode.Hover | null {
    const range = document.getWordRangeAtPosition(position);
    if (!range) {
      return null;
    }
    
    const word = document.getText(range);
    
    // TODO: Implement actual hover logic
    const hoverText = new vscode.MarkdownString();
    hoverText.appendMarkdown(`**NeoAI Hover**\n\n`);
    hoverText.appendMarkdown(`Word: \`${word}\`\n\n`);
    hoverText.appendMarkdown(`Language: ${document.languageId}\n\n`);
    hoverText.appendMarkdown(`*Hover functionality coming soon*`);
    
    return new vscode.Hover(hoverText, range);
  }
}
