import * as vscode from 'vscode';
import { runCompletion } from './runCompletion';
import { CompletionArguments } from './CompletionArguments';
import { CompletionOrigin } from './CompletionOrigin';

export interface CompletionItem {
	text: string;
	insertText?: string;
	range?: vscode.Range;
	kind?: string;
	detail?: string;
	documentation?: string;
	additionalTextEdits?: vscode.TextEdit[];
}

export async function getInlineCompletionItems(
	document: vscode.TextDocument,
	position: vscode.Position,
	context: vscode.InlineCompletionContext | vscode.CompletionContext,
	token: vscode.CancellationToken
): Promise<CompletionItem[]> {
	try {
		// Prepare completion arguments
		const args: CompletionArguments = {
			document,
			position,
			context,
			origin: getCompletionOrigin(context),
			maxTokens: 1000,
			temperature: 0.1
		};

		// Check if cancellation is requested
		if (token.isCancellationRequested) {
			return [];
		}

		// Run the completion
		const result = await runCompletion(args, token);

		if (!result || !result.completions || result.completions.length === 0) {
			return [];
		}

		// Convert and filter completions
		return result.completions
			.filter(completion => completion && completion.text)
			.map(completion => normalizeCompletion(completion, document, position));

	} catch (error) {
		console.error('Error in getInlineCompletionItems:', error);
		return [];
	}
}

function getCompletionOrigin(context: vscode.InlineCompletionContext | vscode.CompletionContext): CompletionOrigin {
	if ('triggerKind' in context) {
		switch (context.triggerKind) {
			case vscode.InlineCompletionTriggerKind.Automatic:
				return CompletionOrigin.Automatic;
			case vscode.InlineCompletionTriggerKind.Invoke:
				return CompletionOrigin.Invoke;
			default:
				return CompletionOrigin.Unknown;
		}
	} else {
		switch (context.triggerKind) {
			case vscode.CompletionTriggerKind.Invoke:
				return CompletionOrigin.Invoke;
			case vscode.CompletionTriggerKind.TriggerCharacter:
				return CompletionOrigin.TriggerCharacter;
			case vscode.CompletionTriggerKind.TriggerForIncompleteCompletions:
				return CompletionOrigin.TriggerForIncompleteCompletions;
			default:
				return CompletionOrigin.Unknown;
		}
	}
}

function normalizeCompletion(
	completion: any,
	document: vscode.TextDocument,
	position: vscode.Position
): CompletionItem {
	const normalized: CompletionItem = {
		text: completion.text || completion.insertText || '',
		insertText: completion.insertText || completion.text || '',
		kind: completion.kind || 'text',
		detail: completion.detail || '',
		documentation: completion.documentation || ''
	};

	// Set range if not provided
	if (completion.range) {
		normalized.range = new vscode.Range(
			completion.range.start.line,
			completion.range.start.character,
			completion.range.end.line,
			completion.range.end.character
		);
	} else {
		// Default range: from current position to end of line
		const line = document.lineAt(position.line);
		normalized.range = new vscode.Range(
			position,
			line.range.end
		);
	}

	// Handle additional text edits
	if (completion.additionalTextEdits) {
		normalized.additionalTextEdits = completion.additionalTextEdits.map((edit: any) =>
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

	return normalized;
}