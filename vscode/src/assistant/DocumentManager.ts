import * as vscode from 'vscode';
import { isValidDocument } from './utils';

/**
 * Document manager for NeoAI Assistant
 */

export interface DocumentInfo {
	uri: vscode.Uri;
	language: string;
	version: number;
	lineCount: number;
	size: number;
	lastModified: number;
	isDirty: boolean;
}

export interface DocumentChange {
	uri: vscode.Uri;
	type: 'create' | 'change' | 'delete' | 'save';
	version?: number;
	range?: vscode.Range;
	text?: string;
}

export class DocumentManager {
	private static instance: DocumentManager;
	private documents: Map<string, DocumentInfo> = new Map();
	private _onDidChange: vscode.EventEmitter<DocumentChange> = new vscode.EventEmitter<DocumentChange>();
	public readonly onDidChange: vscode.Event<DocumentChange> = this._onDidChange.event;
	private disposables: vscode.Disposable[] = [];

	private constructor() {
		this.setupEventListeners();
	}

	static getInstance(): DocumentManager {
		if (!DocumentManager.instance) {
			DocumentManager.instance = new DocumentManager();
		}
		return DocumentManager.instance;
	}

	private setupEventListeners(): void {
		// Listen for document open events
		this.disposables.push(
			vscode.workspace.onDidOpenTextDocument((document) => {
				if (isValidDocument(document)) {
					this.trackDocument(document);
					this._onDidChange.fire({
						uri: document.uri,
						type: 'create',
						version: document.version
					});
				}
			})
		);

		// Listen for document change events
		this.disposables.push(
			vscode.workspace.onDidChangeTextDocument((event) => {
				const document = event.document;
				if (isValidDocument(document)) {
					this.updateDocument(document);
					
					for (const change of event.contentChanges) {
						this._onDidChange.fire({
							uri: document.uri,
							type: 'change',
							version: document.version,
							range: change.range,
							text: change.text
						});
					}
				}
			})
		);

		// Listen for document save events
		this.disposables.push(
			vscode.workspace.onDidSaveTextDocument((document) => {
				if (isValidDocument(document)) {
					this.updateDocument(document);
					this._onDidChange.fire({
						uri: document.uri,
						type: 'save',
						version: document.version
					});
				}
			})
		);

		// Listen for document close events
		this.disposables.push(
			vscode.workspace.onDidCloseTextDocument((document) => {
				this.untrackDocument(document);
				this._onDidChange.fire({
					uri: document.uri,
					type: 'delete'
				});
			})
		);

		// Track existing documents
		this.trackExistingDocuments();
	}

	private trackExistingDocuments(): void {
		for (const document of vscode.workspace.textDocuments) {
			if (isValidDocument(document)) {
				this.trackDocument(document);
			}
		}
	}

	private trackDocument(document: vscode.TextDocument): void {
		const info: DocumentInfo = {
			uri: document.uri,
			language: document.languageId,
			version: document.version,
			lineCount: document.lineCount,
			size: document.getText().length,
			lastModified: Date.now(),
			isDirty: document.isDirty
		};
		this.documents.set(document.uri.toString(), info);
	}

	private updateDocument(document: vscode.TextDocument): void {
		const existing = this.documents.get(document.uri.toString());
		if (existing) {
			existing.version = document.version;
			existing.lineCount = document.lineCount;
			existing.size = document.getText().length;
			existing.lastModified = Date.now();
			existing.isDirty = document.isDirty;
		} else {
			this.trackDocument(document);
		}
	}

	private untrackDocument(document: vscode.TextDocument): void {
		this.documents.delete(document.uri.toString());
	}

	getDocument(uri: vscode.Uri): DocumentInfo | undefined {
		return this.documents.get(uri.toString());
	}

	getDocumentByPath(path: string): DocumentInfo | undefined {
		for (const [uri, info] of this.documents) {
			if (info.uri.fsPath === path) {
				return info;
			}
		}
		return undefined;
	}

	getAllDocuments(): DocumentInfo[] {
		return Array.from(this.documents.values());
	}

	getDocumentsByLanguage(language: string): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => doc.language === language);
	}

	getOpenDocuments(): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => !doc.isDirty);
	}

	getDirtyDocuments(): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => doc.isDirty);
	}

	getActiveDocument(): DocumentInfo | undefined {
		const activeEditor = vscode.window.activeTextEditor;
		if (activeEditor) {
			return this.getDocument(activeEditor.document.uri);
		}
		return undefined;
	}

	isDocumentTracked(uri: vscode.Uri): boolean {
		return this.documents.has(uri.toString());
	}

	getDocumentCount(): number {
		return this.documents.size;
	}

	getDocumentSize(uri: vscode.Uri): number | undefined {
		const doc = this.getDocument(uri);
		return doc?.size;
	}

	getDocumentLanguage(uri: vscode.Uri): string | undefined {
		const doc = this.getDocument(uri);
		return doc?.language;
	}

	isDocumentDirty(uri: vscode.Uri): boolean {
		const doc = this.getDocument(uri);
		return doc?.isDirty ?? false;
	}

	getDocumentVersion(uri: vscode.Uri): number | undefined {
		const doc = this.getDocument(uri);
		return doc?.version;
	}

	getDocumentLineCount(uri: vscode.Uri): number | undefined {
		const doc = this.getDocument(uri);
		return doc?.lineCount;
	}

	/**
	 * Get documents that have been modified since a given timestamp
	 */
	getModifiedDocumentsSince(timestamp: number): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => doc.lastModified > timestamp);
	}

	/**
	 * Get documents larger than a given size
	 */
	getLargeDocuments(minSize: number): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => doc.size > minSize);
	}

	/**
	 * Get documents with line count above a threshold
	 */
	getLongDocuments(minLines: number): DocumentInfo[] {
		return this.getAllDocuments().filter(doc => doc.lineCount > minLines);
	}

	/**
	 * Find documents by content pattern
	 */
	async findDocumentsByContent(pattern: RegExp): Promise<DocumentInfo[]> {
		const matchingDocs: DocumentInfo[] = [];
		
		for (const docInfo of this.getAllDocuments()) {
			try {
				const document = await vscode.workspace.openTextDocument(docInfo.uri);
				const content = document.getText();
				if (pattern.test(content)) {
					matchingDocs.push(docInfo);
				}
			} catch (error) {
				// Skip documents that can't be opened
				continue;
			}
		}
		
		return matchingDocs;
	}

	/**
	 * Get document statistics
	 */
	getStatistics(): {
		total: number;
		byLanguage: Record<string, number>;
		totalSize: number;
		averageSize: number;
		dirtyCount: number;
		largestDocument?: DocumentInfo;
		longestDocument?: DocumentInfo;
	} {
		const docs = this.getAllDocuments();
		const byLanguage: Record<string, number> = {};
		let totalSize = 0;
		let dirtyCount = 0;
		let largestDocument: DocumentInfo | undefined;
		let longestDocument: DocumentInfo | undefined;

		for (const doc of docs) {
			byLanguage[doc.language] = (byLanguage[doc.language] || 0) + 1;
			totalSize += doc.size;
			
			if (doc.isDirty) {
				dirtyCount++;
			}
			
			if (!largestDocument || doc.size > largestDocument.size) {
				largestDocument = doc;
			}
			
			if (!longestDocument || doc.lineCount > longestDocument.lineCount) {
				longestDocument = doc;
			}
		}

		return {
			total: docs.length,
			byLanguage,
			totalSize,
			averageSize: docs.length > 0 ? totalSize / docs.length : 0,
			dirtyCount,
			largestDocument,
			longestDocument
		};
	}

	/**
	 * Clear all tracked documents
	 */
	clear(): void {
		this.documents.clear();
	}

	/**
	 * Dispose of the document manager
	 */
	dispose(): void {
		for (const disposable of this.disposables) {
			disposable.dispose();
		}
		this.disposables = [];
		this.documents.clear();
		this._onDidChange.dispose();
	}
}

/**
 * Utility functions for document management
 */
export namespace DocumentUtils {
	/**
	 * Get the document manager instance
	 */
	export function getDocumentManager(): DocumentManager {
		return DocumentManager.getInstance();
	}

	/**
	 * Check if a URI is a valid text document
	 */
	export function isTextDocument(uri: vscode.Uri): boolean {
		const path = uri.fsPath.toLowerCase();
		const textExtensions = [
			'.txt', '.md', '.json', '.xml', '.yaml', '.yml', '.toml', '.ini',
			'.js', '.ts', '.jsx', '.tsx', '.vue', '.html', '.css', '.scss', '.sass', '.less',
			'.py', '.java', '.c', '.cpp', '.h', '.hpp', '.cs', '.php', '.rb', '.go', '.rs',
			'.sh', '.bat', '.ps1', '.sql', '.graphql', '.dockerfile'
		];
		return textExtensions.some(ext => path.endsWith(ext));
	}

	/**
	 * Get a readable file size string
	 */
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

	/**
	 * Get a relative path from a URI
	 */
	export function getRelativePath(uri: vscode.Uri): string {
		const workspaceFolder = vscode.workspace.getWorkspaceFolder(uri);
		if (workspaceFolder) {
			return uri.fsPath.replace(workspaceFolder.uri.fsPath, '').replace(/^\//, '');
		}
		return uri.fsPath;
	}

	/**
	 * Check if a document is likely to be binary
	 */
	export function isLikelyBinary(document: vscode.TextDocument): boolean {
		const content = document.getText();
		const sampleSize = Math.min(1024, content.length);
		const sample = content.substring(0, sampleSize);
		
		// Check for null bytes (common in binary files)
		if (sample.includes('\0')) {
			return true;
		}
		
		// Check for high ratio of non-printable characters
		const nonPrintable = (sample.match(/[^\x20-\x7E\n\r\t]/g) || []).length;
		const ratio = nonPrintable / sampleSize;
		
		return ratio > 0.3; // More than 30% non-printable suggests binary
	}
}
