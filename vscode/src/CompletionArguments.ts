import * as vscode from 'vscode';
import { CompletionOrigin } from './CompletionOrigin';

export interface CompletionArguments {
	document: vscode.TextDocument;
	position: vscode.Position;
	context: vscode.InlineCompletionContext | vscode.CompletionContext;
	origin: CompletionOrigin;
	maxTokens?: number;
	temperature?: number;
	topP?: number;
	frequencyPenalty?: number;
	presencePenalty?: number;
	stopSequences?: string[];
	model?: string;
	prefix?: string;
	suffix?: string;
}

export interface CompletionResult {
	completions: CompletionItem[];
	model?: string;
	usage?: {
		promptTokens: number;
		completionTokens: number;
		totalTokens: number;
	};
	finishReason?: string;
	created?: number;
	id?: string;
}

export interface CompletionItem {
	text: string;
	insertText?: string;
	range?: vscode.Range;
	kind?: string;
	detail?: string;
	documentation?: string;
	additionalTextEdits?: vscode.TextEdit[];
	score?: number;
	logprobs?: number[];
}