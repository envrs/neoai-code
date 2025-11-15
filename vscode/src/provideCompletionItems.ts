import * as vscode from 'vscode';
import { getInlineCompletionItems } from './getInlineCompletionItems';

export class CompletionItemProvider implements vscode.CompletionItemProvider {
	async provideCompletionItems(
		document: vscode.TextDocument,
		position: vscode.Position,
		token: vscode.CancellationToken,
		context: vscode.CompletionContext
	): Promise<vscode.CompletionItem[]> {
		if (this.shouldDisableCompletion(document, position)) {
			return [];
		}

		try {
			const completions = await getInlineCompletionItems(document, position, context, token);
			return completions.map(completion => this.createCompletionItem(completion));
		} catch (error) {
			console.error('Error providing completion items:', error);
			return [];
		}
	}

	private createCompletionItem(completion: any): vscode.CompletionItem {
		if (typeof completion === 'string') {
			const item = new vscode.CompletionItem(completion, vscode.CompletionItemKind.Text);
			item.insertText = completion;
			return item;
		}

		const item = new vscode.CompletionItem(
			completion.label || completion.text || '',
			this.getCompletionKind(completion.kind)
		);

		item.insertText = completion.insertText || completion.text || '';
		item.detail = completion.detail || '';
		item.documentation = completion.documentation 
			? new vscode.MarkdownString(completion.documentation)
			: undefined;
		
		if (completion.range) {
			item.range = new vscode.Range(
				completion.range.start.line,
				completion.range.start.character,
				completion.range.end.line,
				completion.range.end.character
			);
		}

		if (completion.additionalTextEdits) {
			item.additionalTextEdits = completion.additionalTextEdits.map((edit: any) => 
				new vscode.TextEdit(
					new vscode.Range(
						edit.range.start.line,
						edit.range.start.character,
						edit.range.end.line,
						edit.range.end.character
					),
					edit.newText
				)
			);
		}

		return item;
	}

	private getCompletionKind(kind?: string): vscode.CompletionItemKind {
		switch (kind) {
			case 'method':
				return vscode.CompletionItemKind.Method;
			case 'function':
				return vscode.CompletionItemKind.Function;
			case 'variable':
				return vscode.CompletionItemKind.Variable;
			case 'class':
				return vscode.CompletionItemKind.Class;
			case 'interface':
				return vscode.CompletionItemKind.Interface;
			case 'property':
				return vscode.CompletionItemKind.Property;
			case 'field':
				return vscode.CompletionItemKind.Field;
			case 'constructor':
				return vscode.CompletionItemKind.Constructor;
			case 'keyword':
				return vscode.CompletionItemKind.Keyword;
			case 'snippet':
				return vscode.CompletionItemKind.Snippet;
			case 'file':
				return vscode.CompletionItemKind.File;
			case 'directory':
				return vscode.CompletionItemKind.Folder;
			case 'module':
				return vscode.CompletionItemKind.Module;
			case 'enum':
				return vscode.CompletionItemKind.Enum;
			case 'enumMember':
				return vscode.CompletionItemKind.EnumMember;
			case 'color':
				return vscode.CompletionItemKind.Color;
			case 'reference':
				return vscode.CompletionItemKind.Reference;
			case 'unit':
				return vscode.CompletionItemKind.Unit;
			case 'value':
				return vscode.CompletionItemKind.Value;
			case 'event':
				return vscode.CompletionItemKind.Event;
			case 'operator':
				return vscode.CompletionItemKind.Operator;
			case 'typeParameter':
				return vscode.CompletionItemKind.TypeParameter;
			default:
				return vscode.CompletionItemKind.Text;
		}
	}

	private shouldDisableCompletion(document: vscode.TextDocument, position: vscode.Position): boolean {
		const config = vscode.workspace.getConfiguration('neoai');
		
		// Check file regex patterns
		const disableFileRegex = config.get<string[]>('disableFileRegex', []);
		const filePath = document.uri.fsPath;
		for (const pattern of disableFileRegex) {
			try {
				const regex = new RegExp(pattern);
				if (regex.test(filePath)) {
					return true;
				}
			} catch (error) {
				console.warn(`Invalid regex pattern in disableFileRegex: ${pattern}`);
			}
		}

		// Check line regex patterns
		const disableLineRegex = config.get<string[]>('disableLineRegex', []);
		const lineText = document.lineAt(position.line).text;
		for (const pattern of disableLineRegex) {
			try {
				const regex = new RegExp(pattern);
				if (regex.test(lineText)) {
					return true;
				}
			} catch (error) {
				console.warn(`Invalid regex pattern in disableLineRegex: ${pattern}`);
			}
		}

		return false;
	}
}