import * as vscode from 'vscode';
import { getExtensionContext } from './extension';

export class CommandsHandler {
	private context: vscode.ExtensionContext;

	constructor(context: vscode.ExtensionContext) {
		this.context = context;
	}

	registerCommands(): void {
		// Register all commands defined in package.json
		const commands = [
			'neoai.chat.commands.explain-code',
			'neoai.chat.commands.generate-tests',
			'neoai.chat.commands.document-code',
			'neoai.chat.commands.fix-code',
			'neoai.chat.submit-message',
			'neoai.chat.state',
			'neoai.chat.clear-all-conversations',
			'NeoAi::config',
			'NeoAi::configExternal',
			'NeoAi::assistantClearCache',
			'NeoAi::assistantSetThreshold',
			'NeoAi::assistantToggle',
			'Neoai.hideSuggestion',
			'Neoai.applySuggestion',
			'neoai.logs',
			'neoai.signInUsingAuthToken',
			'neoai.chat.focus-input'
		];

		commands.forEach(command => {
			const disposable = vscode.commands.registerCommand(command, () => {
				this.handleCommand(command);
			});
			this.context.subscriptions.push(disposable);
		});
	}

	private async handleCommand(command: string): Promise<void> {
		switch (command) {
			case 'neoai.chat.commands.explain-code':
				await this.explainCode();
				break;
			case 'neoai.chat.commands.generate-tests':
				await this.generateTests();
				break;
			case 'neoai.chat.commands.document-code':
				await this.documentCode();
				break;
			case 'neoai.chat.commands.fix-code':
				await this.fixCode();
				break;
			case 'NeoAi::config':
				await this.openConfig();
				break;
			case 'NeoAi::configExternal':
				await this.openConfigExternal();
				break;
			case 'NeoAi::assistantToggle':
				await this.toggleAssistant();
				break;
			case 'neoai.logs':
				await this.openLogs();
				break;
			case 'neoai.chat.focus-input':
				await this.focusChatInput();
				break;
			default:
				vscode.window.showInformationMessage(`Command ${command} not implemented yet`);
		}
	}

	private async explainCode(): Promise<void> {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage('No active editor found');
			return;
		}

		const selection = editor.selection;
		const text = editor.document.getText(selection);
		const codeToExplain = text || editor.document.getText();

		// TODO: Implement actual AI explanation
		vscode.window.showInformationMessage('Code explanation feature coming soon!');
	}

	private async generateTests(): Promise<void> {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage('No active editor found');
			return;
		}

		// TODO: Implement test generation
		vscode.window.showInformationMessage('Test generation feature coming soon!');
	}

	private async documentCode(): Promise<void> {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage('No active editor found');
			return;
		}

		// TODO: Implement code documentation
		vscode.window.showInformationMessage('Code documentation feature coming soon!');
	}

	private async fixCode(): Promise<void> {
		const editor = vscode.window.activeTextEditor;
		if (!editor) {
			vscode.window.showErrorMessage('No active editor found');
			return;
		}

		// TODO: Implement code fixing
		vscode.window.showInformationMessage('Code fixing feature coming soon!');
	}

	private async openConfig(): Promise<void> {
		vscode.commands.executeCommand('workbench.action.openSettings', 'neoai');
	}

	private async openConfigExternal(): Promise<void> {
		const config = vscode.workspace.getConfiguration('neoai');
		const configTarget = vscode.ConfigurationTarget.Global;
		// TODO: Open external configuration
		vscode.window.showInformationMessage('External config feature coming soon!');
	}

	private async toggleAssistant(): Promise<void> {
		const config = vscode.workspace.getConfiguration('neoai');
		const currentState = config.get('assistant.enabled', false);
		await config.update('assistant.enabled', !currentState, vscode.ConfigurationTarget.Global);
		
		const newState = !currentState ? 'enabled' : 'disabled';
		vscode.window.showInformationMessage(`NeoAI Assistant ${newState}`);
	}

	private async openLogs(): Promise<void> {
		const logPath = vscode.workspace.getConfiguration('neoai').get('logFilePath');
		if (logPath && typeof logPath === 'string') {
			try {
				const uri = vscode.Uri.file(logPath);
				await vscode.workspace.openTextDocument(uri);
				await vscode.window.showTextDocument(uri);
			} catch (error) {
				vscode.window.showErrorMessage(`Could not open log file: ${error}`);
			}
		} else {
			vscode.window.showInformationMessage('No log file path configured');
		}
	}

	private async focusChatInput(): Promise<void> {
		// TODO: Implement chat input focus
		vscode.window.showInformationMessage('Chat input focus feature coming soon!');
	}
}