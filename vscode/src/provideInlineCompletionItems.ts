import * as vscode from 'vscode';
import { ActiveTextEditorState } from './activeTextEditorState';
import { getInlineCompletionItems } from './getInlineCompletionItems';
import { debounceCompletions } from './debounceCompletions';

export class InlineCompletionProvider implements vscode.InlineCompletionItemProvider {
	private activeTextEditorState: ActiveTextEditorState;
	private debouncedProvider: Function;

	constructor() {
		this.activeTextEditorState = new ActiveTextEditorState();
		this.debouncedProvider = debounceCompletions(
			this.provideInlineCompletionItemsInternal.bind(this),
			vscode.workspace.getConfiguration('neoai').get<number>('debounceMilliseconds', 0)
		);
	}

	async provideInlineCompletionItems(
		document: vscode.TextDocument,
		position: vscode.Position,
		context: vscode.InlineCompletionContext,
		token: vscode.CancellationToken
	): Promise<vscode.InlineCompletionItem[]> {
		if (this.shouldDisableCompletion(document, position)) {
			return [];
		}

		if (context.triggerKind === vscode.InlineCompletionTriggerKind.Automatic) {
			return this.debouncedProvider(document, position, context, token);
		} else {
			return this.provideInlineCompletionItemsInternal(document, position, context, token);
		}
	}

	private async provideInlineCompletionItemsInternal(
		document: vscode.TextDocument,
		position: vscode.Position,
		context: vscode.InlineCompletionContext,
		token: vscode.CancellationToken
	): Promise<vscode.InlineCompletionItem[]> {
		try {
			const completions = await getInlineCompletionItems(document, position, context, token);
			return completions.map(completion => this.createInlineCompletionItem(completion));
		} catch (error) {
			console.error('Error providing inline completions:', error);
			return [];
		}
	}

	private createInlineCompletionItem(completion: any): vscode.InlineCompletionItem {
		if (typeof completion === 'string') {
			return new vscode.InlineCompletionItem(completion, new vscode.Range(0, 0, 0, 0));
		}
		
		if (completion.insertText && completion.range) {
			return new vscode.InlineCompletionItem(
				completion.insertText,
				new vscode.Range(
					completion.range.start.line,
					completion.range.start.character,
					completion.range.end.line,
					completion.range.end.character
				)
			);
		}

		return new vscode.InlineCompletionItem(completion.text || '', new vscode.Range(0, 0, 0, 0));
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

		// Check if we're in a comment
		if (this.isInComment(document, position)) {
			return true;
		}

		// Check if we're in a string literal
		if (this.isInString(document, position)) {
			return true;
		}

		return false;
	}

	private isInComment(document: vscode.TextDocument, position: vscode.Position): boolean {
		const line = document.lineAt(position.line);
		const textBefore = line.text.substring(0, position.character);
		
		// Simple comment detection for common languages
		const languageId = document.languageId;
		
		switch (languageId) {
			case 'javascript':
			case 'typescript':
			case 'java':
			case 'c':
			case 'cpp':
			case 'csharp':
				// Check for // comments
				if (textBefore.includes('//')) {
					return true;
				}
				// Check for /* */ comments
				const beforeCursor = document.getText(new vscode.Range(new vscode.Position(0, 0), position));
				const commentStarts = (beforeCursor.match(/\/\*/g) || []).length;
				const commentEnds = (beforeCursor.match(/\*\//g) || []).length;
				return commentStarts > commentEnds;
				
			case 'python':
				// Check for # comments
				return textBefore.includes('#');
				
			case 'html':
			case 'xml':
				// Check for <!-- --> comments
				const htmlBeforeCursor = document.getText(new vscode.Range(new vscode.Position(0, 0), position));
				const htmlCommentStarts = (htmlBeforeCursor.match(/<!--/g) || []).length;
				const htmlCommentEnds = (htmlBeforeCursor.match(/-->/g) || []).length;
				return htmlCommentStarts > htmlCommentEnds;
				
			case 'css':
				// Check for /* */ comments
				const cssBeforeCursor = document.getText(new vscode.Range(new vscode.Position(0, 0), position));
				const cssCommentStarts = (cssBeforeCursor.match(/\/\*/g) || []).length;
				const cssCommentEnds = (cssBeforeCursor.match(/\*\//g) || []).length;
				return cssCommentStarts > cssCommentEnds;
				
			default:
				return false;
		}
	}

	private isInString(document: vscode.TextDocument, position: vscode.Position): boolean {
		const line = document.lineAt(position.line);
		const textBefore = line.text.substring(0, position.character);
		const languageId = document.languageId;
		
		switch (languageId) {
			case 'javascript':
			case 'typescript':
			case 'java':
			case 'c':
			case 'cpp':
			case 'csharp':
				// Count quotes before cursor
				const singleQuotes = (textBefore.match(/'/g) || []).length;
				const doubleQuotes = (textBefore.match(/"/g) || []).length;
				const backticks = (textBefore.match(/`/g) || []).length;
				
				// Simple heuristic: odd number of quotes means we're in a string
				return singleQuotes % 2 === 1 || doubleQuotes % 2 === 1 || backticks % 2 === 1;
				
			case 'python':
				// Count quotes before cursor
				const pySingleQuotes = (textBefore.match(/'/g) || []).length;
				const pyDoubleQuotes = (textBefore.match(/"/g) || []).length;
				
				return pySingleQuotes % 2 === 1 || pyDoubleQuotes % 2 === 1;
				
			default:
				return false;
		}
	}

	dispose(): void {
		this.activeTextEditorState.dispose();
	}
}