// Import VSCode types - these will be available at runtime in VSCode extension host
import * as vscode from 'vscode';
import { CommandsHandler } from './commandsHandler';
import { InlineCompletionProvider } from './provideInlineCompletionItems';
import { CompletionItemProvider } from './provideCompletionItems';
import { ActiveTextEditorState } from './activeTextEditorState';
import { ProxyProvider } from './proxyProvider';

let extensionContext: vscode.ExtensionContext;

export function activate(context: vscode.ExtensionContext) {
	extensionContext = context;
	
	console.log('NeoAI extension is now active!');

	// Initialize commands handler
	const commandsHandler = new CommandsHandler(context);
	commandsHandler.registerCommands();

	// Initialize providers
	const inlineCompletionProvider = new InlineCompletionProvider();
	const completionProvider = new CompletionItemProvider();
	const activeTextEditorState = new ActiveTextEditorState();
	const proxyProvider = new ProxyProvider();

	// Register inline completion provider
	context.subscriptions.push(
		vscode.languages.registerInlineCompletionItemProvider(
			[{ pattern: '**' }], // All files
			inlineCompletionProvider
		)
	);

	// Register completion provider
	context.subscriptions.push(
		vscode.languages.registerCompletionItemProvider(
			[{ pattern: '**' }], // All files
			completionProvider,
			'.', // Trigger on dot
			'(', // Trigger on opening parenthesis
			'<'  // Trigger on less than sign
		)
	);

	// Store instances for global access
	context.subscriptions.push({
		dispose: () => {
			inlineCompletionProvider.dispose();
			activeTextEditorState.dispose();
			proxyProvider.dispose();
		}
	});

	console.log('NeoAI extension activated successfully');
}

export function deactivate() {
	console.log('NeoAI extension deactivated');
}

export function getExtensionContext(): vscode.ExtensionContext {
	return extensionContext;
}