import * as vscode from 'vscode';
import { DiagnosticSeverity } from './globals';
import { createRange } from './Range';

/**
 * NeoAI Diagnostic implementation
 */

export interface NeoAiDiagnosticData {
	type: 'suggestion' | 'warning' | 'error' | 'info';
	source: string;
	confidence: number;
	suggestion?: string;
	fix?: {
		title: string;
		edit: vscode.TextEdit;
	};
}

export class NeoAiDiagnostic {
	public readonly range: vscode.Range;
	public readonly message: string;
	public readonly severity: vscode.DiagnosticSeverity;
	public readonly source: string = 'NeoAI';
	public readonly data?: NeoAiDiagnosticData;

	constructor(
		range: vscode.Range,
		message: string,
		severity: vscode.DiagnosticSeverity = vscode.DiagnosticSeverity.Information,
		data?: NeoAiDiagnosticData
	) {
		this.range = range;
		this.message = message;
		this.severity = severity;
		this.data = data;
	}

	static create(
		document: vscode.TextDocument,
		startLine: number,
		startChar: number,
		endLine: number,
		endChar: number,
		message: string,
		severity: DiagnosticSeverity = DiagnosticSeverity.Information,
		data?: NeoAiDiagnosticData
	): NeoAiDiagnostic {
		const range = createRange(startLine, startChar, endLine, endChar);
		const vscodeSeverity = this.mapSeverity(severity);
		return new NeoAiDiagnostic(range, message, vscodeSeverity, data);
	}

	static fromRange(
		range: vscode.Range,
		message: string,
		severity: DiagnosticSeverity = DiagnosticSeverity.Information,
		data?: NeoAiDiagnosticData
	): NeoAiDiagnostic {
		const vscodeSeverity = this.mapSeverity(severity);
		return new NeoAiDiagnostic(range, message, vscodeSeverity, data);
	}

	private static mapSeverity(severity: DiagnosticSeverity): vscode.DiagnosticSeverity {
		switch (severity) {
			case DiagnosticSeverity.Error:
				return vscode.DiagnosticSeverity.Error;
			case DiagnosticSeverity.Warning:
				return vscode.DiagnosticSeverity.Warning;
			case DiagnosticSeverity.Hint:
				return vscode.DiagnosticSeverity.Hint;
			case DiagnosticSeverity.Information:
			default:
				return vscode.DiagnosticSeverity.Information;
		}
	}

	withSeverity(severity: DiagnosticSeverity): NeoAiDiagnostic {
		const vscodeSeverity = NeoAiDiagnostic.mapSeverity(severity);
		return new NeoAiDiagnostic(this.range, this.message, vscodeSeverity, this.data);
	}

	withMessage(message: string): NeoAiDiagnostic {
		return new NeoAiDiagnostic(this.range, message, this.severity, this.data);
	}

	withRange(range: vscode.Range): NeoAiDiagnostic {
		return new NeoAiDiagnostic(range, this.message, this.severity, this.data);
	}

	withData(data: NeoAiDiagnosticData): NeoAiDiagnostic {
		return new NeoAiDiagnostic(this.range, this.message, this.severity, data);
	}

	isSuggestion(): boolean {
		return this.data?.type === 'suggestion';
	}

	isWarning(): boolean {
		return this.data?.type === 'warning' || this.severity === vscode.DiagnosticSeverity.Warning;
	}

	isError(): boolean {
		return this.data?.type === 'error' || this.severity === vscode.DiagnosticSeverity.Error;
	}

	hasFix(): boolean {
		return !!this.data?.fix;
	}

	getFix(): { title: string; edit: vscode.TextEdit } | undefined {
		return this.data?.fix;
	}

	getConfidence(): number {
		return this.data?.confidence ?? 0;
	}

	getSuggestion(): string | undefined {
		return this.data?.suggestion;
	}

	toJSON(): object {
		return {
			range: {
				start: {
					line: this.range.start.line,
					character: this.range.start.character
				},
				end: {
					line: this.range.end.line,
					character: this.range.end.character
				}
			},
			message: this.message,
			severity: this.severity,
			source: this.source,
			data: this.data
		};
	}

	static fromJSON(json: any): NeoAiDiagnostic {
		const range = createRange(
			json.range.start.line,
			json.range.start.character,
			json.range.end.line,
			json.range.end.character
		);
		return new NeoAiDiagnostic(range, json.message, json.severity, json.data);
	}
}

/**
 * Diagnostic collection manager
 */
export class NeoAiDiagnosticCollection {
	private diagnostics: Map<string, NeoAiDiagnostic[]> = new Map();
	private _onDidChange: vscode.EventEmitter<void> = new vscode.EventEmitter<void>();
	public readonly onDidChange: vscode.Event<void> = this._onDidChange.event;

	set(uri: string, diagnostics: NeoAiDiagnostic[]): void {
		this.diagnostics.set(uri, diagnostics);
		this._onDidChange.fire();
	}

	get(uri: string): NeoAiDiagnostic[] {
		return this.diagnostics.get(uri) ?? [];
	}

	has(uri: string): boolean {
		return this.diagnostics.has(uri);
	}

	delete(uri: string): boolean {
		const result = this.diagnostics.delete(uri);
		if (result) {
			this._onDidChange.fire();
		}
		return result;
	}

	clear(): void {
		this.diagnostics.clear();
		this._onDidChange.fire();
	}

	getAll(): Map<string, NeoAiDiagnostic[]> {
		return new Map(this.diagnostics);
	}

	getSize(): number {
		return this.diagnostics.size;
	}

	getDiagnosticsCount(): number {
		let count = 0;
		for (const diagnostics of this.diagnostics.values()) {
			count += diagnostics.length;
		}
		return count;
	}

	getDiagnosticsByType(type: NeoAiDiagnosticData['type']): Map<string, NeoAiDiagnostic[]> {
		const result = new Map<string, NeoAiDiagnostic[]>();
		
		for (const [uri, diagnostics] of this.diagnostics) {
			const filtered = diagnostics.filter(d => d.data?.type === type);
			if (filtered.length > 0) {
				result.set(uri, filtered);
			}
		}
		
		return result;
	}

	getDiagnosticsBySeverity(severity: vscode.DiagnosticSeverity): Map<string, NeoAiDiagnostic[]> {
		const result = new Map<string, NeoAiDiagnostic[]>();
		
		for (const [uri, diagnostics] of this.diagnostics) {
			const filtered = diagnostics.filter(d => d.severity === severity);
			if (filtered.length > 0) {
				result.set(uri, filtered);
			}
		}
		
		return result;
	}
}

/**
 * Utility functions for creating common diagnostics
 */
export namespace NeoAiDiagnostics {
	export function createSuggestion(
		range: vscode.Range,
		message: string,
		suggestion?: string,
		confidence = 0.8
	): NeoAiDiagnostic {
		return NeoAiDiagnostic.fromRange(range, message, DiagnosticSeverity.Information, {
			type: 'suggestion',
			source: 'neoai-suggestion',
			confidence,
			suggestion
		});
	}

	export function createWarning(
		range: vscode.Range,
		message: string,
		confidence = 0.9
	): NeoAiDiagnostic {
		return NeoAiDiagnostic.fromRange(range, message, DiagnosticSeverity.Warning, {
			type: 'warning',
			source: 'neoai-warning',
			confidence
		});
	}

	export function createError(
		range: vscode.Range,
		message: string,
		confidence = 0.95
	): NeoAiDiagnostic {
		return NeoAiDiagnostic.fromRange(range, message, DiagnosticSeverity.Error, {
			type: 'error',
			source: 'neoai-error',
			confidence
		});
	}

	export function createFixableDiagnostic(
		range: vscode.Range,
		message: string,
		fixTitle: string,
		fixEdit: vscode.TextEdit,
		confidence = 0.85
	): NeoAiDiagnostic {
		return NeoAiDiagnostic.fromRange(range, message, DiagnosticSeverity.Information, {
			type: 'suggestion',
			source: 'neoai-fix',
			confidence,
			fix: {
				title: fixTitle,
				edit: fixEdit
			}
		});
	}
}