import * as vscode from 'vscode';
import { AssistantMode, DiagnosticSeverity } from './globals';

/**
 * Utility functions for the NeoAI Assistant
 */

export function debounce<T extends (...args: any[]) => any>(
	func: T,
	wait: number
): (...args: Parameters<T>) => void {
	let timeout: ReturnType<typeof setTimeout>;
	return (...args: Parameters<T>) => {
		clearTimeout(timeout);
		timeout = setTimeout(() => func(...args), wait);
	};
}

export function throttle<T extends (...args: any[]) => any>(
	func: T,
	limit: number
): (...args: Parameters<T>) => void {
	let inThrottle: boolean;
	return (...args: Parameters<T>) => {
		if (!inThrottle) {
			func(...args);
			inThrottle = true;
			setTimeout(() => (inThrottle = false), limit);
		}
	};
}

export function isValidDocument(document: vscode.TextDocument): boolean {
	if (!document) return false;
	
	// Check if document is not untitled and has a valid URI
	if (document.uri.scheme === 'untitled') return false;
	
	// Check if document is not too large (limit to 1MB)
	const content = document.getText();
	if (content.length > 1024 * 1024) return false;
	
	// Check if document has supported language
	const supportedLanguages = [
		'typescript', 'javascript', 'python', 'java', 'csharp', 'cpp', 'c',
		'go', 'rust', 'php', 'ruby', 'swift', 'kotlin', 'scala', 'html',
		'css', 'json', 'xml', 'yaml', 'markdown', 'sql', 'shell'
	];
	
	return supportedLanguages.includes(document.languageId);
}

export function getCurrentLineText(editor: vscode.TextEditor): string {
	if (!editor) return '';
	const position = editor.selection.active;
	return editor.document.lineAt(position.line).text;
}

export function getCurrentWord(editor: vscode.TextEditor): string {
	if (!editor) return '';
	const position = editor.selection.active;
	const range = editor.document.getWordRangeAtPosition(position);
	return range ? editor.document.getText(range) : '';
}

export function getSelectionText(editor: vscode.TextEditor): string {
	if (!editor) return '';
	const selection = editor.selection;
	return editor.document.getText(selection);
}

// Simplified diagnostic creation since vscode.Diagnostic is not available
export function createDiagnosticMessage(
	message: string,
	severity: DiagnosticSeverity = DiagnosticSeverity.Information
): { message: string; severity: DiagnosticSeverity } {
	return { message, severity };
}

export function formatFileSize(bytes: number): string {
	const units = ['B', 'KB', 'MB', 'GB'];
	let size = bytes;
	let unitIndex = 0;
	
	while (size >= 1024 && unitIndex < units.length - 1) {
		size /= 1024;
		unitIndex++;
	}
	
	return `${size.toFixed(1)} ${units[unitIndex]}`;
}

export function sanitizeFileName(name: string): string {
	return name.replace(/[^a-zA-Z0-9._-]/g, '_');
}

export function extractCodeFromMarkdown(markdown: string): string {
	const codeBlockRegex = /```[\w]*\n?([\s\S]*?)```/g;
	const matches = [];
	let match;
	
	while ((match = codeBlockRegex.exec(markdown)) !== null) {
		matches.push(match[1]);
	}
	
	return matches.join('\n\n');
}

export function isPositionInRange(position: vscode.Position, range: vscode.Range): boolean {
	return position.isAfterOrEqual(range.start) && position.isBeforeOrEqual(range.end);
}

export function getRelativePath(uri: vscode.Uri): string {
	// Simple relative path calculation
	const fsPath = uri.fsPath;
	const parts = fsPath.split('/');
	return parts.slice(-2).join('/'); // Return last 2 parts as relative path
}

// Simplified quick pick since showQuickPick is not available
export async function showQuickPick<T>(
	items: T[],
	placeholder: string
): Promise<T | undefined> {
	// Fallback to simple input selection
	const itemsStr = items.map((item, index) => `${index + 1}. ${item}`).join('\n');
	const choice = await vscode.window.showInformationMessage(
		`${placeholder}\n\n${itemsStr}\n\nEnter choice number (1-${items.length}):`,
		...items.map(item => String(item))
	);
	
	return items.find(item => String(item) === choice);
}

export function getExtensionVersion(): string {
	// Fallback version since extensions API is not available
	return '1.0.0';
}

export function logMessage(message: string, level: 'info' | 'warn' | 'error' = 'info'): void {
	const timestamp = new Date().toISOString();
	const logMessage = `[${timestamp}] [NeoAI] ${message}`;
	
	switch (level) {
		case 'error':
			console.error(logMessage);
			break;
		case 'warn':
			console.warn(logMessage);
			break;
		default:
			console.log(logMessage);
	}
}