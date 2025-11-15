import * as vscode from 'vscode';
import { DocumentManager } from './assistant/DocumentManager';

/**
 * Import finding functionality for NeoAI Assistant
 */

export interface ImportInfo {
	name: string;
	source: string;
	isDefault: boolean;
	isTypeOnly: boolean;
	range: vscode.Range;
	line: number;
	column: number;
}

export interface ImportSuggestion {
	name: string;
	source: string;
	description?: string;
	isPackage: boolean;
	isLocal: boolean;
	confidence: number;
}

export interface FindImportsOptions {
	includePackageImports?: boolean;
	includeLocalImports?: boolean;
	includeTypeImports?: boolean;
	maxResults?: number;
}

export class ImportFinder {
	private static instance: ImportFinder;
	private documentManager: DocumentManager;
	private packageCache: Map<string, PackageInfo> = new Map();
	private disposables: vscode.Disposable[] = [];

	private constructor() {
		this.documentManager = DocumentManager.getInstance();
		this.setupEventListeners();
	}

	static getInstance(): ImportFinder {
		if (!ImportFinder.instance) {
			ImportFinder.instance = new ImportFinder();
		}
		return ImportFinder.instance;
	}

	private setupEventListeners(): void {
		// Clear cache when workspace changes
		this.disposables.push(
			vscode.workspace.onDidChangeWorkspaceFolders(() => {
				this.packageCache.clear();
			})
		);
	}

	/**
	 * Find all imports in a document
	 */
	findImports(document: vscode.TextDocument, options: FindImportsOptions = {}): ImportInfo[] {
		const imports: ImportInfo[] = [];
		const text = document.getText();
		const lines = text.split('\n');

		for (let lineNum = 0; lineNum < lines.length; lineNum++) {
			const line = lines[lineNum];
			const lineImports = this.parseLineImports(line, lineNum, options);
			imports.push(...lineImports);
		}

		return imports;
	}

	/**
	 * Parse imports from a single line
	 */
	private parseLineImports(line: string, lineNum: number, options: FindImportsOptions): ImportInfo[] {
		const imports: ImportInfo[] = [];

		// Match ES6 import statements
		const importRegex = /import\s+(?:(type\s+)?(.+?)\s+from\s+)?['"`]([^'"`]+)['"`]/g;
		let match;

		while ((match = importRegex.exec(line)) !== null) {
			const isTypeOnly = !!match[1];
			const importClause = match[2];
			const source = match[3];

			if (!options.includeTypeImports && isTypeOnly) {
				continue;
			}

			const startIndex = match.index;
			const endIndex = startIndex + match[0].length;

			// Parse individual imports from the clause
			if (importClause) {
				const individualImports = this.parseImportClause(importClause, source, isTypeOnly, lineNum, startIndex);
				imports.push(...individualImports);
			} else {
				// Default import: import name from 'source'
				const importInfo: ImportInfo = {
					name: importClause || 'default',
					source,
					isDefault: !importClause,
					isTypeOnly,
					range: new vscode.Range(lineNum, startIndex, lineNum, endIndex),
					line: lineNum,
					column: startIndex
				};
				imports.push(importInfo);
			}
		}

		// Match CommonJS require statements
		const requireRegex = /(?:const|let|var)\s+(?:(.+?)\s*=\s*)?require\(['"`]([^'"`]+)['"`]\)/g;
		while ((match = requireRegex.exec(line)) !== null) {
			const variableName = match[1];
			const source = match[2];
			const startIndex = match.index;
			const endIndex = startIndex + match[0].length;

			const importInfo: ImportInfo = {
				name: variableName || 'default',
				source,
				isDefault: true,
				isTypeOnly: false,
				range: new vscode.Range(lineNum, startIndex, lineNum, endIndex),
				line: lineNum,
				column: startIndex
			};
			imports.push(importInfo);
		}

		return imports;
	}

	/**
	 * Parse import clause to extract individual imports
	 */
	private parseImportClause(
		clause: string,
		source: string,
		isTypeOnly: boolean,
		lineNum: number,
		startIndex: number
	): ImportInfo[] {
		const imports: ImportInfo[] = [];

		// Handle named imports: { name1, name2 as alias }
		const namedImportRegex = /\{([^}]+)\}/;
		const namedMatch = clause.match(namedImportRegex);

		if (namedMatch) {
			const namedImports = namedMatch[1].split(',').map(s => s.trim());
			for (const namedImport of namedImports) {
				const parts = namedImport.split(' as ').map(s => s.trim());
				const name = parts[0];
				const alias = parts[1] || name;

				if (name) {
					imports.push({
						name: alias,
						source,
						isDefault: false,
						isTypeOnly,
						range: new vscode.Range(lineNum, startIndex, lineNum, startIndex + clause.length),
						line: lineNum,
						column: startIndex
					});
				}
			}
		} else {
			// Default import
			imports.push({
				name: clause,
				source,
				isDefault: true,
				isTypeOnly,
				range: new vscode.Range(lineNum, startIndex, lineNum, startIndex + clause.length),
				line: lineNum,
				column: startIndex
			});
		}

		return imports;
	}

	/**
	 * Find unused imports in a document
	 */
	async findUnusedImports(document: vscode.TextDocument): Promise<ImportInfo[]> {
		const imports = this.findImports(document);
		const text = document.getText();
		const unused: ImportInfo[] = [];

		for (const importInfo of imports) {
			const isUsed = this.checkImportUsage(importInfo, text);
			if (!isUsed) {
				unused.push(importInfo);
			}
		}

		return unused;
	}

	/**
	 * Check if an import is used in the document
	 */
	private checkImportUsage(importInfo: ImportInfo, text: string): boolean {
		// Create regex patterns to find usage
		const patterns = [
			new RegExp(`\\b${importInfo.name}\\b`, 'g'),
			new RegExp(`\\b${importInfo.source}\\b`, 'g') // Check for direct usage of source
		];

		// Skip the import declaration itself
		const importLine = text.split('\n')[importInfo.line];
		const textWithoutImport = text.replace(importLine, '');

		for (const pattern of patterns) {
			const matches = textWithoutImport.match(pattern);
			if (matches && matches.length > 0) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Suggest imports for a given identifier
	 */
	async suggestImports(
		identifier: string,
		document: vscode.TextDocument,
		options: FindImportsOptions = {}
	): Promise<ImportSuggestion[]> {
		const suggestions: ImportSuggestion[] = [];

		// Check package imports
		if (options.includePackageImports !== false) {
			const packageSuggestions = await this.suggestPackageImports(identifier);
			suggestions.push(...packageSuggestions);
		}

		// Check local imports
		if (options.includeLocalImports !== false) {
			const localSuggestions = await this.suggestLocalImports(identifier, document);
			suggestions.push(...localSuggestions);
		}

		// Sort by confidence and limit results
		suggestions.sort((a, b) => b.confidence - a.confidence);
		return suggestions.slice(0, options.maxResults || 10);
	}

	/**
	 * Suggest package imports
	 */
	private async suggestPackageImports(identifier: string): Promise<ImportSuggestion[]> {
		const suggestions: ImportSuggestion[] = [];

		// Check common packages that might export this identifier
		const commonPackages = this.getCommonPackagesForIdentifier(identifier);
		
		for (const packageName of commonPackages) {
			const packageInfo = await this.getPackageInfo(packageName);
			if (packageInfo && packageInfo.exports.includes(identifier)) {
				suggestions.push({
					name: identifier,
					source: packageName,
					description: packageInfo.description,
					isPackage: true,
					isLocal: false,
					confidence: this.calculatePackageConfidence(packageName, identifier)
				});
			}
		}

		return suggestions;
	}

	/**
	 * Suggest local imports
	 */
	private async suggestLocalImports(
		identifier: string,
		document: vscode.TextDocument
	): Promise<ImportSuggestion[]> {
		const suggestions: ImportSuggestion[] = [];
		const workspaceFolders = vscode.workspace.workspaceFolders || [];

		for (const folder of workspaceFolders) {
			const localFiles = await this.findLocalFiles(folder, identifier);
			suggestions.push(...localFiles.map(file => ({
				name: identifier,
				source: file.relativePath,
				description: `Local file: ${file.relativePath}`,
				isPackage: false,
				isLocal: true,
				confidence: this.calculateLocalConfidence(file, identifier)
			})));
		}

		return suggestions;
	}

	/**
	 * Get common packages that might export an identifier
	 */
	private getCommonPackagesForIdentifier(identifier: string): string[] {
		const commonPackages: Record<string, string[]> = {
			// React
			'React': ['react'],
			'Component': ['react'],
			'useState': ['react'],
			'useEffect': ['react'],
			'useContext': ['react'],
			
			// Node.js
			'fs': ['fs'],
			'path': ['path'],
			'http': ['http'],
			'https': ['https'],
			'url': ['url'],
			'util': ['util'],
			'events': ['events'],
			'stream': ['stream'],
			
			// Common utilities
			'lodash': ['lodash'],
			'_': ['lodash'],
			'moment': ['moment'],
			'axios': ['axios'],
			'express': ['express'],
			'cors': ['cors'],
			'bodyParser': ['body-parser'],
			
			// TypeScript
			'Readonly': ['typescript'],
			'Record': ['typescript'],
			'Partial': ['typescript'],
			'Required': ['typescript'],
			'Pick': ['typescript'],
			'Omit': ['typescript'],
		};

		return commonPackages[identifier] || [];
	}

	/**
	 * Get package information from npm registry
	 */
	private async getPackageInfo(packageName: string): Promise<PackageInfo | null> {
		if (this.packageCache.has(packageName)) {
			return this.packageCache.get(packageName)!;
		}

		try {
			// This would normally fetch from npm registry
			// For now, return mock data
			const packageInfo: PackageInfo = {
				name: packageName,
				version: '1.0.0',
				description: `Package ${packageName}`,
				exports: [] // Would be populated from package.json
			};

			this.packageCache.set(packageName, packageInfo);
			return packageInfo;
		} catch (error) {
			console.error(`Failed to fetch package info for ${packageName}:`, error);
			return null;
		}
	}

	/**
	 * Find local files that might contain the identifier
	 */
	private async findLocalFiles(
		folder: vscode.WorkspaceFolder,
		identifier: string
	): Promise<LocalFile[]> {
		const files: LocalFile[] = [];
		const pattern = `**/*.{js,ts,jsx,tsx,d.ts}`;
		
		try {
			const uris = await vscode.workspace.findFiles(pattern, '**/node_modules/**');
			
			for (const uri of uris) {
				if (!uri.fsPath.startsWith(folder.uri.fsPath)) {
					continue;
				}

				const document = await vscode.workspace.openTextDocument(uri);
				const text = document.getText();
				
				// Check if the identifier is exported
				if (this.checkIfExported(identifier, text)) {
					const relativePath = uri.fsPath.replace(folder.uri.fsPath, '').replace(/^\//, '');
					files.push({
						path: uri.fsPath,
						relativePath,
						exports: [identifier]
					});
				}
			}
		} catch (error) {
			console.error('Error finding local files:', error);
		}

		return files;
	}

	/**
	 * Check if an identifier is exported from a file
	 */
	private checkIfExported(identifier: string, text: string): boolean {
		const exportPatterns = [
			new RegExp(`export\\s+(?:const|let|var|function|class)\\s+${identifier}\\b`, 'g'),
			new RegExp(`export\\s*{[^}]*${identifier}[^}]*}`, 'g'),
			new RegExp(`export\\s+default\\s+${identifier}\\b`, 'g'),
			new RegExp(`module\\.exports\\s*=\\s*${identifier}\\b`, 'g'),
			new RegExp(`exports\\.${identifier}\\s*=`, 'g')
		];

		return exportPatterns.some(pattern => pattern.test(text));
	}

	/**
	 * Calculate confidence score for package import
	 */
	private calculatePackageConfidence(packageName: string, identifier: string): number {
		// Higher confidence for well-known packages
		const wellKnownPackages = ['react', 'lodash', 'moment', 'axios', 'express'];
		const baseScore = wellKnownPackages.includes(packageName) ? 0.8 : 0.5;
		
		// Adjust based on identifier specificity
		const identifierScore = identifier.length > 3 ? 0.1 : 0.05;
		
		return Math.min(1.0, baseScore + identifierScore);
	}

	/**
	 * Calculate confidence score for local import
	 */
	private calculateLocalConfidence(file: LocalFile, identifier: string): number {
		// Higher confidence for files with fewer exports (more specific)
		const exportCount = file.exports.length;
		const specificityScore = exportCount === 1 ? 0.8 : Math.max(0.3, 0.8 - (exportCount * 0.1));
		
		// Prefer closer files
		const depth = file.relativePath.split('/').length;
		const proximityScore = Math.max(0.1, 0.5 - (depth * 0.1));
		
		return Math.min(1.0, specificityScore + proximityScore);
	}

	/**
	 * Auto-import an identifier at the cursor position
	 */
	async autoImport(
		document: vscode.TextDocument,
		position: vscode.Position,
		identifier: string
	): Promise<boolean> {
		const suggestions = await this.suggestImports(identifier, document);
		
		if (suggestions.length === 0) {
			return false;
		}

		// Use the highest confidence suggestion
		const suggestion = suggestions[0];
		
		try {
			const editor = vscode.window.activeTextEditor;
			if (!editor) {
				return false;
			}

			// Find the best place to insert the import
			const insertPosition = this.findBestImportInsertPosition(document);
			
			if (insertPosition) {
				const importStatement = this.generateImportStatement(suggestion);
				await editor.edit(editBuilder => {
					editBuilder.insert(insertPosition, importStatement + '\n');
				});
				return true;
			}
		} catch (error) {
			console.error('Failed to auto-import:', error);
		}

		return false;
	}

	/**
	 * Find the best position to insert an import statement
	 */
	private findBestImportInsertPosition(document: vscode.TextDocument): vscode.Position | null {
		const text = document.getText();
		const lines = text.split('\n');
		
		// Look for existing imports
		let lastImportLine = -1;
		
		for (let i = 0; i < lines.length; i++) {
			const line = lines[i].trim();
			if (line.startsWith('import ') || line.startsWith('require(')) {
				lastImportLine = i;
			} else if (lastImportLine >= 0 && line.length > 0) {
				// Found first non-import line after imports
				break;
			}
		}
		
		if (lastImportLine >= 0) {
			// Insert after the last import
			return new vscode.Position(lastImportLine + 1, 0);
		} else {
			// Insert at the beginning of the file (after any shebang or comments)
			for (let i = 0; i < lines.length; i++) {
				const line = lines[i].trim();
				if (line.length > 0 && !line.startsWith('#') && !line.startsWith('//') && !line.startsWith('/*')) {
					return new vscode.Position(i, 0);
				}
			}
		}
		
		return new vscode.Position(0, 0);
	}

	/**
	 * Generate import statement from suggestion
	 */
	private generateImportStatement(suggestion: ImportSuggestion): string {
		if (suggestion.isDefault) {
			return `import ${suggestion.name} from '${suggestion.source}';`;
		} else {
			return `import { ${suggestion.name} } from '${suggestion.source}';`;
		}
	}

	/**
	 * Clear package cache
	 */
	clearCache(): void {
		this.packageCache.clear();
	}

	/**
	 * Dispose of the import finder
	 */
	dispose(): void {
		for (const disposable of this.disposables) {
			disposable.dispose();
		}
		this.disposables = [];
		this.packageCache.clear();
	}
}

/**
 * Package information interface
 */
interface PackageInfo {
	name: string;
	version: string;
	description: string;
	exports: string[];
}

/**
 * Local file information interface
 */
interface LocalFile {
	path: string;
	relativePath: string;
	exports: string[];
}

/**
 * Utility functions for import management
 */
export namespace ImportUtils {
	/**
	 * Get the import finder instance
	 */
	export function getImportFinder(): ImportFinder {
		return ImportFinder.getInstance();
	}

	/**
	 * Show import suggestions quick pick
	 */
	export async function showImportSuggestions(
		identifier: string,
		document: vscode.TextDocument
	): Promise<void> {
		const finder = getImportFinder();
		const suggestions = await finder.suggestImports(identifier, document);

		if (suggestions.length === 0) {
			vscode.window.showInformationMessage(`No import suggestions found for '${identifier}'`);
			return;
		}

		const items = suggestions.map(suggestion => ({
			label: suggestion.name,
			description: suggestion.source,
			detail: suggestion.description,
			suggestion
		}));

		const chosen = await vscode.window.showQuickPick(items, {
			placeHolder: `Select import for '${identifier}'`
		});

		if (chosen) {
			const editor = vscode.window.activeTextEditor;
			if (editor) {
				const insertPosition = finder['findBestImportInsertPosition'](document);
				if (insertPosition) {
					const importStatement = finder['generateImportStatement'](chosen.suggestion);
					await editor.edit(editBuilder => {
						editBuilder.insert(insertPosition, importStatement + '\n');
					});
				}
			}
		}
	}

	/**
	 * Find and remove unused imports
	 */
	export async function removeUnusedImports(document: vscode.TextDocument): Promise<void> {
		const finder = getImportFinder();
		const unusedImports = await finder.findUnusedImports(document);

		if (unusedImports.length === 0) {
			vscode.window.showInformationMessage('No unused imports found');
			return;
		}

		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			return;
		}

		await editor.edit(editBuilder => {
			// Remove imports in reverse order to maintain line numbers
			unusedImports.reverse().forEach(importInfo => {
				editBuilder.delete(importInfo.range);
			});
		});

		vscode.window.showInformationMessage(`Removed ${unusedImports.length} unused imports`);
	}
}