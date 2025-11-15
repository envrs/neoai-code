import * as vscode from 'vscode';
import { DocumentManager } from './assistant/DocumentManager';

/**
 * Workspace updater for NeoAI Assistant
 */

export interface WorkspaceUpdate {
	type: 'document' | 'configuration' | 'workspace';
	uri?: vscode.Uri;
	timestamp: number;
	data?: any;
}

export interface WorkspaceUpdateOptions {
	debounceMs?: number;
	includeDirty?: boolean;
	excludePatterns?: string[];
}

export class WorkspaceUpdater {
	private static instance: WorkspaceUpdater;
	private updates: WorkspaceUpdate[] = [];
	private isUpdating: boolean = false;
	private debounceTimer: NodeJS.Timeout | undefined;
	private documentManager: DocumentManager;
	private disposables: vscode.Disposable[] = [];
	private _onDidUpdate: vscode.EventEmitter<WorkspaceUpdate> = new vscode.EventEmitter<WorkspaceUpdate>();
	public readonly onDidUpdate: vscode.Event<WorkspaceUpdate> = this._onDidUpdate.event;

	private constructor() {
		this.documentManager = DocumentManager.getInstance();
		this.setupEventListeners();
	}

	static getInstance(): WorkspaceUpdater {
		if (!WorkspaceUpdater.instance) {
			WorkspaceUpdater.instance = new WorkspaceUpdater();
		}
		return WorkspaceUpdater.instance;
	}

	private setupEventListeners(): void {
		// Listen for document changes
		this.disposables.push(
			this.documentManager.onDidChange((change) => {
				this.queueUpdate({
					type: 'document',
					uri: change.uri,
					timestamp: Date.now(),
					data: change
				});
			})
		);

		// Listen for configuration changes
		this.disposables.push(
			vscode.workspace.onDidChangeConfiguration((event) => {
				this.queueUpdate({
					type: 'configuration',
					timestamp: Date.now(),
					data: { affectsConfiguration: event.affectsConfiguration }
				});
			})
		);

		// Listen for workspace folder changes
		this.disposables.push(
			vscode.workspace.onDidChangeWorkspaceFolders((event) => {
				this.queueUpdate({
					type: 'workspace',
					timestamp: Date.now(),
					data: {
						added: event.added,
						removed: event.removed
					}
				});
			})
		);
	}

	private queueUpdate(update: WorkspaceUpdate): void {
		this.updates.push(update);
		this.scheduleUpdate();
	}

	private scheduleUpdate(): void {
		if (this.debounceTimer) {
			clearTimeout(this.debounceTimer);
		}

		this.debounceTimer = setTimeout(() => {
			this.processUpdates();
		}, 100); // 100ms debounce
	}

	private async processUpdates(): Promise<void> {
		if (this.isUpdating || this.updates.length === 0) {
			return;
		}

		this.isUpdating = true;
		const updates = [...this.updates];
		this.updates = [];

		try {
			// Group updates by type
			const grouped = this.groupUpdates(updates);

			// Process each group
			for (const [type, typeUpdates] of grouped) {
				await this.processUpdateGroup(type, typeUpdates);
			}
		} catch (error) {
			console.error('Error processing workspace updates:', error);
		} finally {
			this.isUpdating = false;

			// If there are new updates, process them
			if (this.updates.length > 0) {
				this.scheduleUpdate();
			}
		}
	}

	private groupUpdates(updates: WorkspaceUpdate[]): Map<string, WorkspaceUpdate[]> {
		const grouped = new Map<string, WorkspaceUpdate[]>();

		for (const update of updates) {
			const key = update.type;
			if (!grouped.has(key)) {
				grouped.set(key, []);
			}
			grouped.get(key)!.push(update);
		}

		return grouped;
	}

	private async processUpdateGroup(type: string, updates: WorkspaceUpdate[]): Promise<void> {
		switch (type) {
			case 'document':
				await this.processDocumentUpdates(updates);
				break;
			case 'configuration':
				await this.processConfigurationUpdates(updates);
				break;
			case 'workspace':
				await this.processWorkspaceUpdates(updates);
				break;
		}
	}

	private async processDocumentUpdates(updates: WorkspaceUpdate[]): Promise<void> {
		// Get unique URIs
		const uniqueUris = new Set<string>();
		for (const update of updates) {
			if (update.uri) {
				uniqueUris.add(update.uri.toString());
			}
		}

		// Process each unique document
		for (const uriStr of uniqueUris) {
			const uri = vscode.Uri.parse(uriStr);
			const update = {
				type: 'document' as const,
				uri,
				timestamp: Date.now(),
				data: this.documentManager.getDocument(uri)
			};

			this._onDidUpdate.fire(update);
		}
	}

	private async processConfigurationUpdates(updates: WorkspaceUpdate[]): Promise<void> {
		for (const update of updates) {
			this._onDidUpdate.fire(update);
		}
	}

	private async processWorkspaceUpdates(updates: WorkspaceUpdate[]): Promise<void> {
		for (const update of updates) {
			this._onDidUpdate.fire(update);
		}
	}

	/**
	 * Force an immediate update of the workspace
	 */
	async forceUpdate(): Promise<void> {
		if (this.debounceTimer) {
			clearTimeout(this.debounceTimer);
		}
		await this.processUpdates();
	}

	/**
	 * Get the current state of the workspace
	 */
	getWorkspaceState(): {
		documents: number;
		folders: number;
		lastUpdate: number;
	} {
		const stats = this.documentManager.getStatistics();
		
		return {
			documents: stats.total,
			folders: vscode.workspace.workspaceFolders?.length ?? 0,
			lastUpdate: Math.max(...this.updates.map(u => u.timestamp))
		};
	}

	/**
	 * Check if the workspace is currently updating
	 */
	isCurrentlyUpdating(): boolean {
		return this.isUpdating;
	}

	/**
	 * Get pending updates
	 */
	getPendingUpdates(): WorkspaceUpdate[] {
		return [...this.updates];
	}

	/**
	 * Clear pending updates
	 */
	clearPendingUpdates(): void {
		this.updates = [];
		if (this.debounceTimer) {
			clearTimeout(this.debounceTimer);
			this.debounceTimer = undefined;
		}
	}

	/**
	 * Get recent updates within a time window
	 */
	getRecentUpdates(timeWindowMs = 5000): WorkspaceUpdate[] {
		const cutoff = Date.now() - timeWindowMs;
		return this.updates.filter(update => update.timestamp > cutoff);
	}

	/**
	 * Subscribe to specific update types
	 */
	onUpdateType(
		type: WorkspaceUpdate['type'],
		callback: (update: WorkspaceUpdate) => void
	): vscode.Disposable {
		const disposable = this._onDidUpdate.event((update) => {
			if (update.type === type) {
				callback(update);
			}
		});

		return disposable;
	}

	/**
	 * Get updates for a specific document
	 */
	getDocumentUpdates(uri: vscode.Uri, timeWindowMs = 5000): WorkspaceUpdate[] {
		const cutoff = Date.now() - timeWindowMs;
		return this.updates.filter(update => 
			update.type === 'document' && 
			update.uri?.toString() === uri.toString() &&
			update.timestamp > cutoff
		);
	}

	/**
	 * Check if a document has recent updates
	 */
	hasRecentUpdates(uri: vscode.Uri, timeWindowMs = 1000): boolean {
		return this.getDocumentUpdates(uri, timeWindowMs).length > 0;
	}

	/**
	 * Dispose of the workspace updater
	 */
	dispose(): void {
		this.clearPendingUpdates();
		for (const disposable of this.disposables) {
			disposable.dispose();
		}
		this.disposables = [];
		this._onDidUpdate.dispose();
	}
}

/**
 * Utility functions for workspace management
 */
export namespace WorkspaceUtils {
	/**
	 * Get the workspace updater instance
	 */
	export function getWorkspaceUpdater(): WorkspaceUpdater {
		return WorkspaceUpdater.getInstance();
	}

	/**
	 * Get workspace folder information
	 */
	export function getWorkspaceFolders(): vscode.WorkspaceFolder[] {
		return vscode.workspace.workspaceFolders ?? [];
	}

	/**
	 * Get the workspace root URI
	 */
	export function getWorkspaceRoot(): vscode.Uri | undefined {
		const folders = getWorkspaceFolders();
		return folders.length > 0 ? folders[0].uri : undefined;
	}

	/**
	 * Check if a URI is within the workspace
	 */
	export function isInWorkspace(uri: vscode.Uri): boolean {
		const folders = getWorkspaceFolders();
		return folders.some(folder => uri.fsPath.startsWith(folder.uri.fsPath));
	}

	/**
	 * Get relative path from workspace root
	 */
	export function getWorkspaceRelativePath(uri: vscode.Uri): string | undefined {
		const root = getWorkspaceRoot();
		if (!root) {
			return undefined;
		}

		if (uri.fsPath.startsWith(root.fsPath)) {
			return uri.fsPath.substring(root.fsPath.length).replace(/^\//, '');
		}

		return undefined;
	}

	/**
	 * Find files matching a pattern
	 */
	export async function findFiles(
		pattern: string,
		exclude?: string,
		maxResults?: number
	): Promise<vscode.Uri[]> {
		return await vscode.workspace.findFiles(pattern, exclude, maxResults);
	}

	/**
	 * Get workspace configuration
	 */
	export function getConfiguration(section?: string): vscode.WorkspaceConfiguration {
		return vscode.workspace.getConfiguration(section);
	}

	/**
	 * Open a text document
	 */
	export async function openTextDocument(uri: vscode.Uri): Promise<vscode.TextDocument> {
		return await vscode.workspace.openTextDocument(uri);
	}

	/**
	 * Show a text document
	 */
	export async function showTextDocument(
		uri: vscode.Uri,
		options?: vscode.TextDocumentShowOptions
	): Promise<vscode.TextEditor> {
		const document = await openTextDocument(uri);
		return await vscode.window.showTextDocument(document, options);
	}

	/**
	 * Get workspace statistics
	 */
	export function getWorkspaceStatistics(): {
		folders: number;
		totalFiles: number;
		languages: Record<string, number>;
		size: string;
	} {
		const folders = getWorkspaceFolders();
		const documentManager = DocumentManager.getInstance();
		const stats = documentManager.getStatistics();

		return {
			folders: folders.length,
			totalFiles: stats.total,
			languages: stats.byLanguage,
			size: formatFileSize(stats.totalSize)
		};
	}

	/**
	 * Format file size for display
	 */
	function formatFileSize(bytes: number): string {
		const units = ['B', 'KB', 'MB', 'GB'];
		let size = bytes;
		let unitIndex = 0;

		while (size >= 1024 && unitIndex < units.length - 1) {
			size /= 1024;
			unitIndex++;
		}

		return `${size.toFixed(1)} ${units[unitIndex]}`;
	}
}