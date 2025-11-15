rimport * as vscode from 'vscode';

/**
 * Range utilities and extensions for the NeoAI Assistant
 */

export interface SimpleRange {
	start: { line: number; character: number };
	end: { line: number; character: number };
}

export function createRange(startLine: number, startChar: number, endLine: number, endChar: number): vscode.Range {
	const startPos = vscode.Position(startLine, startChar);
	const endPos = vscode.Position(endLine, endChar);
	return vscode.Range(startPos, endPos);
}

export function createRangeFromPositions(start: vscode.Position, end: vscode.Position): vscode.Range {
	return vscode.Range(start, end);
}

export function rangeContains(range: vscode.Range, position: vscode.Position): boolean {
	return position.isAfterOrEqual(range.start) && position.isBeforeOrEqual(range.end);
}

export function rangeEquals(range1: vscode.Range, range2: vscode.Range): boolean {
	return range1.start.isEqual(range2.start) && range1.end.isEqual(range2.end);
}

export function rangeIsEmpty(range: vscode.Range): boolean {
	return range.start.isEqual(range.end);
}

export function getRangeLength(range: vscode.Range, document: vscode.TextDocument): number {
	if (range.start.line === range.end.line) {
		return range.end.character - range.start.character;
	}
	
	let length = 0;
	for (let line = range.start.line; line <= range.end.line; line++) {
		const lineText = document.lineAt(line).text;
		if (line === range.start.line) {
			length += lineText.length - range.start.character;
		} else if (line === range.end.line) {
			length += range.end.character;
		} else {
			length += lineText.length + 1; // +1 for newline
		}
	}
	return length;
}

export function expandRange(range: vscode.Range, linesBefore: number, linesAfter: number, document: vscode.TextDocument): vscode.Range {
	const startLine = Math.max(0, range.start.line - linesBefore);
	const endLine = Math.min(document.getLineCount() - 1, range.end.line + linesAfter);
	
	const startChar = startLine === range.start.line ? range.start.character : 0;
	const endChar = endLine === range.end.line ? range.end.character : document.lineAt(endLine).text.length;
	
	return vscode.Range(vscode.Position(startLine, startChar), vscode.Position(endLine, endChar));
}

export function getWordRangeAtPosition(document: vscode.TextDocument, position: vscode.Position): vscode.Range | undefined {
	const line = document.lineAt(position.line);
	const text = line.text;
	const index = position.character;
	
	if (index >= text.length) return undefined;
	
	// Find word boundaries
	let start = index;
	while (start > 0 && /\w/.test(text[start - 1])) {
		start--;
	}
	
	let end = index;
	while (end < text.length && /\w/.test(text[end])) {
		end++;
	}
	
	if (start === end) return undefined;
	
	return vscode.Range(vscode.Position(position.line, start), vscode.Position(position.line, end));
}

export function getLineRange(document: vscode.TextDocument, lineNumber: number): vscode.Range {
	const line = document.lineAt(lineNumber);
	return vscode.Range(vscode.Position(lineNumber, 0), vscode.Position(lineNumber, line.text.length));
}

export function getDocumentRange(document: vscode.TextDocument): vscode.Range {
	const firstLine = document.lineAt(0);
	const lastLine = document.lineAt(document.getLineCount() - 1);
	return vscode.Range(vscode.Position(0, 0), vscode.Position(lastLine.lineNumber, lastLine.text.length));
}

export function intersectRanges(range1: vscode.Range, range2: vscode.Range): vscode.Range | undefined {
	const start = range1.start.isAfter(range2.start) ? range1.start : range2.start;
	const end = range1.end.isBefore(range2.end) ? range1.end : range2.end;
	
	if (start.isAfterOrEqual(end)) return undefined;
	
	return vscode.Range(start, end);
}

export function unionRanges(range1: vscode.Range, range2: vscode.Range): vscode.Range {
	const start = range1.start.isBefore(range2.start) ? range1.start : range2.start;
	const end = range1.end.isAfter(range2.end) ? range1.end : range2.end;
	
	return vscode.Range(start, end);
}