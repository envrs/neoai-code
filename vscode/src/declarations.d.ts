declare module 'vscode' {
	interface ExtensionContext {
		globalState: Memento;
		workspaceState: Memento;
		subscriptions: Disposable[];
		extensionPath: string;
		storagePath?: string;
		globalStoragePath: string;
		logPath: string;
		extensionUri: Uri;
		extensionMode: ExtensionMode;
		environmentVariableCollection: EnvironmentVariableCollection;
		secretStorage: SecretStorage;
	}
}

declare namespace NodeJS {
	interface ProcessEnv {
		[key: string]: string | undefined;
	}
}

declare global {
	interface Window {
		[key: string]: any;
	}
}

export {};