import * as vscode from 'vscode';

/**
 * CancellationToken implementation for NeoAI Assistant operations
 */

export class NeoAiCancellationToken implements vscode.CancellationToken {
	private _isCancelled: boolean = false;
	private _onCancellationRequestedCallbacks: ((event: any) => void)[] = [];

	get isCancellationRequested(): boolean {
		return this._isCancelled;
	}

	onCancellationRequested = (listener: (e: any) => any): vscode.Disposable => {
		this._onCancellationRequestedCallbacks.push(listener);
		
		return {
			dispose: () => {
				const index = this._onCancellationRequestedCallbacks.indexOf(listener);
				if (index !== -1) {
					this._onCancellationRequestedCallbacks.splice(index, 1);
				}
			}
		};
	};

	cancel(): void {
		if (!this._isCancelled) {
			this._isCancelled = true;
			this._fireCancellationRequested();
		}
	}

	reset(): void {
		this._isCancelled = false;
	}

	private _fireCancellationRequested(): void {
		this._onCancellationRequestedCallbacks.forEach(callback => {
			try {
				callback(undefined);
			} catch (error) {
				console.error('Error in cancellation callback:', error);
			}
		});
	}
}

/**
 * CancellationToken source that can create and cancel tokens
 */
export class CancellationTokenSource {
	private _token: NeoAiCancellationToken;

	constructor() {
		this._token = new NeoAiCancellationToken();
	}

	get token(): vscode.CancellationToken {
		return this._token;
	}

	cancel(): void {
		this._token.cancel();
	}

	dispose(): void {
		this.cancel();
	}
}

/**
 * Utility functions for working with cancellation tokens
 */
export namespace CancellationTokenUtils {
	export function createCancellationTokenSource(): CancellationTokenSource {
		return new CancellationTokenSource();
	}

	export function createCombinedToken(...tokens: vscode.CancellationToken[]): vscode.CancellationToken {
		const combinedToken = new NeoAiCancellationToken();
		
		// Set up listeners on all source tokens
		tokens.forEach(token => {
			if (token.isCancellationRequested) {
				combinedToken.cancel();
				return;
			}
			
			token.onCancellationRequested(() => {
				combinedToken.cancel();
			});
		});
		
		return combinedToken;
	}

	export function throwIfCancelled(token: vscode.CancellationToken): void {
		if (token.isCancellationRequested) {
			throw new Error('Operation cancelled');
		}
	}

	export function withTimeout<T>(
		token: vscode.CancellationToken,
		timeoutMs: number,
		onTimeout?: () => void
	): vscode.CancellationToken {
		const timeoutSource = new CancellationTokenSource();
		const timeoutHandle = setTimeout(() => {
			timeoutSource.cancel();
			if (onTimeout) {
				onTimeout();
			}
		}, timeoutMs);

		// Cancel timeout if original token is cancelled
		token.onCancellationRequested(() => {
			clearTimeout(timeoutHandle);
			timeoutSource.cancel();
		});

		// Cancel timeout source if original token is cancelled
		const combinedToken = createCombinedToken(token, timeoutSource.token);

		// Clean up timeout when combined token is cancelled
		combinedToken.onCancellationRequested(() => {
			clearTimeout(timeoutHandle);
		});

		return combinedToken;
	}
}