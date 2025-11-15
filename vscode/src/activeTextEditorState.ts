import * as vscode from 'vscode';

export interface EditorState {
	document: vscode.TextDocument;
	selection: vscode.Selection;
	cursorPosition: vscode.Position;
	languageId: string;
	filePath: string;
	lastModified: number;
}

export class ActiveTextEditorState implements vscode.Disposable {
	private _onDidChangeActiveTextEditor = new vscode.EventEmitter<vscode.TextEditor | undefined>();
	private _onDidChangeTextEditorSelection = new vscode.EventEmitter<vscode.TextEditorSelectionChangeEvent>();
	private _onDidChangeTextDocument = new vscode.EventEmitter<vscode.TextDocumentChangeEvent>();
	
	private currentState: EditorState | undefined;
	private disposables: vscode.Disposable[] = [];

	public readonly onDidChangeActiveTextEditor = this._onDidChangeActiveTextEditor.event;
	public readonly onDidChangeTextEditorSelection = this._onDidChangeTextEditorSelection.event;
	public readonly onDidChangeTextDocument = this._onDidChangeTextDocument.event;

	constructor() {
		this.initialize();
	}

	private initialize(): void {
		// Listen for active editor changes
		this.disposables.push(
			vscode.window.onDidChangeActiveTextEditor(editor => {
				this.updateState(editor);
				this._onDidChangeActiveTextEditor.fire(editor);
			})
		);

		// Listen for selection changes
		this.disposables.push(
			vscode.window.onDidChangeTextEditorSelection(event => {
				if (event.textEditor === vscode.window.activeTextEditor) {
					this.updateState(event.textEditor);
					this._onDidChangeTextEditorSelection.fire(event);
				}
			})
		);

		// Listen for document changes
		this.disposables.push(
			vscode.workspace.onDidChangeTextDocument(event => {
				if (event.document === vscode.window.activeTextEditor?.document) {
					this.updateState(vscode.window.activeTextEditor);
					this._onDidChangeTextDocument.fire(event);
				}
			})
		);

		// Initialize with current editor
		if (vscode.window.activeTextEditor) {
			this.updateState(vscode.window.activeTextEditor);
		}
	}

	private updateState(editor: vscode.TextEditor | undefined): void {
		if (!editor) {
			this.currentState = undefined;
			return;
		}

		this.currentState = {
			document: editor.document,
			selection: editor.selection,
			cursorPosition: editor.selection.active,
			languageId: editor.document.languageId,
			filePath: editor.document.uri.fsPath,
			lastModified: Date.now()
		};
	}

	public getState(): EditorState | undefined {
		return this.currentState;
	}

	public getDocument(): vscode.TextDocument | undefined {
		return this.currentState?.document;
	}

	public getSelection(): vscode.Selection | undefined {
		return this.currentState?.selection;
	}

	public getCursorPosition(): vscode.Position | undefined {
		return this.currentState?.cursorPosition;
	}

	public getLanguageId(): string | undefined {
		return this.currentState?.languageId;
	}

	public getFilePath(): string | undefined {
		return this.currentState?.filePath;
	}

	public getSelectedText(): string | undefined {
		if (!this.currentState) {
			return undefined;
		}

		const { document, selection } = this.currentState;
		return document.getText(selection);
	}

	public getCurrentLine(): string | undefined {
		if (!this.currentState) {
			return undefined;
		}

		const { document, cursorPosition } = this.currentState;
		return document.lineAt(cursorPosition.line).text;
	}

	public getCurrentLineText(): string | undefined {
		if (!this.currentState) {
			return undefined;
		}

		const { document, cursorPosition } = this.currentState;
		const line = document.lineAt(cursorPosition.line);
		return line.text.substring(0, cursorPosition.character);
	}

	public getTextBeforeCursor(maxCharacters: number = 1000): string | undefined {
		if (!this.currentState) {
			return undefined;
		}

		const { document, cursorPosition } = this.currentState;
		const offset = document.offsetAt(cursorPosition);
		const startOffset = Math.max(0, offset - maxCharacters);
		const range = new vscode.Range(
			document.positionAt(startOffset),
			cursorPosition
		);
		return document.getText(range);
	}

	public getTextAfterCursor(maxCharacters: number = 1000): string | undefined {
		if (!this.currentState) {
			return undefined;
		}

		const { document, cursorPosition } = this.currentState;
		const offset = document.offsetAt(cursorPosition);
		const endOffset = Math.min(document.getText().length, offset + maxCharacters);
		const range = new vscode.Range(
			cursorPosition,
			document.positionAt(endOffset)
		);
		return document.getText(range);
	}

	public isAtStartOfLine(): boolean {
		if (!this.currentState) {
			return false;
		}

		const { cursorPosition } = this.currentState;
		return cursorPosition.character === 0;
	}

	public isAtEndOfLine(): boolean {
		if (!this.currentState) {
			return false;
		}

		const { document, cursorPosition } = this.currentState;
		const line = document.lineAt(cursorPosition.line);
		return cursorPosition.character >= line.range.end.character;
	}

	dispose(): void {
		this.disposables.forEach(disposable => disposable.dispose());
		this._onDidChangeActiveTextEditor.dispose();
		this._onDidChangeTextEditorSelection.dispose();
		this._onDidChangeTextDocument.dispose();
	}
}