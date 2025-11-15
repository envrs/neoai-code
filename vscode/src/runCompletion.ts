import * as vscode from 'vscode';
import { CompletionArguments, CompletionResult } from './CompletionArguments';
import { ProxyProvider } from './proxyProvider';

export async function runCompletion(
	args: CompletionArguments,
	token: vscode.CancellationToken
): Promise<CompletionResult> {
	try {
		// Check for cancellation
		if (token.isCancellationRequested) {
			return { completions: [] };
		}

		// Get configuration
		const config = vscode.workspace.getConfiguration('neoai');
		const cloudHost = config.get<string>('cloudHost');
		const ignoreCertificateErrors = config.get<boolean>('ignoreCertificateErrors', false);

		// Prepare the prompt
		const prompt = preparePrompt(args);

		// Make API request
		const response = await makeApiRequest(prompt, args, cloudHost, ignoreCertificateErrors);

		// Parse response
		return parseResponse(response);

	} catch (error) {
		console.error('Error in runCompletion:', error);
		return { completions: [] };
	}
}

function preparePrompt(args: CompletionArguments): string {
	const { document, position } = args;
	
	// Get context around the cursor
	const textBeforeCursor = document.getText(new vscode.Range(
		new vscode.Position(0, 0),
		position
	));
	
	const textAfterCursor = document.getText(new vscode.Range(
		position,
		new vscode.Position(document.lineCount, 0)
	));

	// Get a reasonable amount of context (e.g., 2000 characters before and after)
	const contextBefore = textBeforeCursor.slice(-2000);
	const contextAfter = textAfterCursor.slice(0, 1000);

	// Build the prompt
	const prompt = `
Language: ${document.languageId}
File: ${document.uri.fsPath}

Context before cursor:
${contextBefore}

Context after cursor:
${contextAfter}

Provide code completion for the cursor position:
`;

	return prompt;
}

async function makeApiRequest(
	prompt: string,
	args: CompletionArguments,
	cloudHost?: string,
	ignoreCertificateErrors?: boolean
): Promise<any> {
	const config = vscode.workspace.getConfiguration('neoai');
	
	// For now, return a mock response since we don't have the actual API
	// In a real implementation, this would make an HTTP request to the NeoAI API
	console.log('Making API request to NeoAI service...');
	console.log('Prompt:', prompt);
	console.log('Args:', args);
	
	// Simulate API delay
	await new Promise(resolve => setTimeout(resolve, 100));
	
	// Mock response
	return {
		choices: [
			{
				text: generateMockCompletion(args),
				finish_reason: 'stop',
				index: 0
			}
		],
		usage: {
			prompt_tokens: 100,
			completion_tokens: 50,
			total_tokens: 150
		},
		model: 'neoai-code-completion',
		created: Date.now(),
		id: 'mock-completion-id'
	};
}

function generateMockCompletion(args: CompletionArguments): string {
	const { document, position } = args;
	const languageId = document.languageId;
	
	// Generate context-aware mock completions based on language
	switch (languageId) {
		case 'typescript':
		case 'javascript':
			return generateJavaScriptCompletion(document, position);
		case 'python':
			return generatePythonCompletion(document, position);
		case 'java':
			return generateJavaCompletion(document, position);
		case 'json':
			return generateJsonCompletion(document, position);
		default:
			return generateGenericCompletion(document, position);
	}
}

function generateJavaScriptCompletion(document: vscode.TextDocument, position: vscode.Position): string {
	const line = document.lineAt(position.line).text;
	const textBefore = line.substring(0, position.character);
	
	// Simple heuristics for JavaScript/TypeScript
	if (textBefore.endsWith('function ')) {
		return 'methodName() {\n  // TODO: implement\n}';
	}
	if (textBefore.endsWith('const ')) {
		return 'variableName = initialValue;';
	}
	if (textBefore.endsWith('if (')) {
		return 'condition) {\n  // TODO: handle condition\n}';
	}
	if (textBefore.endsWith('class ')) {
		return 'ClassName {\n  constructor() {\n    // TODO: initialize\n  }\n}';
	}
	
	return '// TODO: add implementation';
}

function generatePythonCompletion(document: vscode.TextDocument, position: vscode.Position): string {
	const line = document.lineAt(position.line).text;
	const textBefore = line.substring(0, position.character);
	
	// Simple heuristics for Python
	if (textBefore.endsWith('def ')) {
		return 'method_name(self):\n    """TODO: Add docstring"""\n    pass';
	}
	if (textBefore.endsWith('class ')) {
		return 'ClassName:\n    """TODO: Add docstring"""\n    def __init__(self):\n        pass';
	}
	if (textBefore.endsWith('if ')) {
		return 'condition:\n    # TODO: handle condition\n    pass';
	}
	
	return '# TODO: add implementation';
}

function generateJavaCompletion(document: vscode.TextDocument, position: vscode.Position): string {
	const line = document.lineAt(position.line).text;
	const textBefore = line.substring(0, position.character);
	
	// Simple heuristics for Java
	if (textBefore.endsWith('public void ')) {
		return 'methodName() {\n  // TODO: implement\n}';
	}
	if (textBefore.endsWith('public class ')) {
		return 'ClassName {\n  // TODO: add fields and methods\n}';
	}
	if (textBefore.endsWith('if (')) {
		return 'condition) {\n  // TODO: handle condition\n}';
	}
	
	return '// TODO: add implementation';
}

function generateJsonCompletion(document: vscode.TextDocument, position: vscode.Position): string {
	const line = document.lineAt(position.line).text;
	const textBefore = line.substring(0, position.character);
	
	// Simple heuristics for JSON
	if (textBefore.endsWith('{')) {
		return '\n  "key": "value"\n}';
	}
	if (textBefore.endsWith('[')) {
		return '\n  {\n    "item": "value"\n  }\n]';
	}
	
	return '"key": "value"';
}

function generateGenericCompletion(document: vscode.TextDocument, position: vscode.Position): string {
	return '// TODO: add implementation';
}

function parseResponse(response: any): CompletionResult {
	if (!response || !response.choices || response.choices.length === 0) {
		return { completions: [] };
	}

	const choice = response.choices[0];
	const completionText = choice.text || '';

	return {
		completions: [
			{
				text: completionText,
				insertText: completionText,
				kind: 'text',
				score: 1.0
			}
		],
		model: response.model,
		usage: response.usage,
		finishReason: choice.finish_reason,
		created: response.created,
		id: response.id
	};
}