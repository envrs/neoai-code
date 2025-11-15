import * as vscode from 'vscode';

/**
 * Progress indicator implementation for NeoAI Assistant operations
 */

export interface ProgressOptions {
	title: string;
	location?: vscode.ProgressLocation;
	cancellable?: boolean;
}

export interface ProgressReport {
	message?: string;
	increment?: number;
	total?: number;
}

export class ProgressIndicator {
	private static activeProgress: ProgressIndicator | null = null;
	private _progress: vscode.Progress<{ message?: string; increment?: number }> | undefined;
	private _cancellationToken: vscode.CancellationToken | undefined;
	private _isDisposed: boolean = false;

	private constructor(
		private readonly options: ProgressOptions,
		private readonly resolve: () => void,
		private readonly reject: (error: any) => void
	) {}

	static async show<T>(
		options: ProgressOptions,
		task: (
			progress: (report: ProgressReport) => void,
			token: vscode.CancellationToken
		) => Promise<T>
	): Promise<T> {
		// Dispose any existing progress
		if (ProgressIndicator.activeProgress) {
			ProgressIndicator.activeProgress.dispose();
		}

		return new Promise<T>((resolve, reject) => {
			const progressIndicator = new ProgressIndicator(options, resolve, reject);
			ProgressIndicator.activeProgress = progressIndicator;

			const location = options.location ?? vscode.ProgressLocation.Notification;

			vscode.window.withProgress(
				{
					location,
					title: options.title,
					cancellable: options.cancellable ?? false
				},
				async (progress, token) => {
					progressIndicator._progress = progress;
					progressIndicator._cancellationToken = token;

					// Handle cancellation
					if (options.cancellable) {
						token.onCancellationRequested(() => {
							if (!progressIndicator._isDisposed) {
								progressIndicator._isDisposed = true;
								ProgressIndicator.activeProgress = null;
								reject(new Error('Operation cancelled'));
							}
						});
					}

					try {
						const result = await task(
							(report) => progressIndicator.report(report),
							token
						);
						
						if (!progressIndicator._isDisposed) {
							progressIndicator._isDisposed = true;
							ProgressIndicator.activeProgress = null;
							resolve(result);
						}
					} catch (error) {
						if (!progressIndicator._isDisposed) {
							progressIndicator._isDisposed = true;
							ProgressIndicator.activeProgress = null;
							reject(error);
						}
					}
				}
			);
		});
	}

	report(report: ProgressReport): void {
		if (this._isDisposed || !this._progress) {
			return;
		}

		this._progress.report({
			message: report.message,
			increment: report.increment
		});
	}

	updateMessage(message: string): void {
		this.report({ message });
	}

	increment(amount = 10): void {
		this.report({ increment: amount });
	}

	setPercentage(percentage: number): void {
		// Calculate increment based on current state
		// This is a simplified approach
		this.report({ increment: percentage });
	}

	isCancelled(): boolean {
		return this._cancellationToken?.isCancellationRequested ?? false;
	}

	dispose(): void {
		if (!this._isDisposed) {
			this._isDisposed = true;
			if (ProgressIndicator.activeProgress === this) {
				ProgressIndicator.activeProgress = null;
			}
		}
	}

	/**
	 * Create a simple progress indicator that shows a message
	 */
	static async showSimpleMessage(
		title: string,
		message: string,
		durationMs = 3000
	): Promise<void> {
		await ProgressIndicator.show(
			{
				title,
				cancellable: false
			},
			async (progress) => {
				progress.report({ message });
				
				// Wait for the specified duration
				await new Promise(resolve => setTimeout(resolve, durationMs));
			}
		);
	}

	/**
	 * Create an indeterminate progress indicator
	 */
	static async showIndeterminate(
		title: string,
		task: (progress: (message: string) => void, token: vscode.CancellationToken) => Promise<void>
	): Promise<void> {
		await ProgressIndicator.show(
			{
				title,
				cancellable: true
			},
			async (progress, token) => {
				await task(
					(message) => progress.report({ message }),
					token
				);
			}
		);
	}

	/**
	 * Create a determinate progress indicator with percentage
	 */
	static async showDeterminate(
		title: string,
		totalSteps: number,
		task: (
			progress: (step: number, message: string) => void,
			token: vscode.CancellationToken
		) => Promise<void>
	): Promise<void> {
		let currentStep = 0;
		const incrementPerStep = 100 / totalSteps;

		await ProgressIndicator.show(
			{
				title,
				cancellable: true
			},
			async (progress, token) => {
				await task(
					(step, message) => {
						const stepIncrement = (step - currentStep) * incrementPerStep;
						currentStep = step;
						progress.report({
							message,
							increment: stepIncrement
						});
					},
					token
				);
			}
		);
	}

	/**
	 * Get the currently active progress indicator
	 */
	static getActiveProgress(): ProgressIndicator | null {
		return ProgressIndicator.activeProgress;
	}

	/**
	 * Cancel the currently active progress indicator
	 */
	static cancelActiveProgress(): boolean {
		if (ProgressIndicator.activeProgress) {
			ProgressIndicator.activeProgress.dispose();
			return true;
		}
		return false;
	}
}

/**
 * Utility functions for common progress scenarios
 */
export namespace ProgressUtils {
	/**
	 * Show progress while processing multiple items
	 */
	export async function processItems<T, R>(
		items: T[],
		title: string,
		processItem: (item: T, index: number, total: number) => Promise<R>
	): Promise<R[]> {
		const results: R[] = [];

		await ProgressIndicator.showDeterminate(
			title,
			items.length,
			async (progress, token) => {
				for (let i = 0; i < items.length; i++) {
					if (token.isCancellationRequested) {
						throw new Error('Operation cancelled');
					}

					const item = items[i];
					const result = await processItem(item, i, items.length);
					results.push(result);

					progress(i + 1, `Processed ${i + 1}/${items.length} items`);
				}
			}
		);

		return results;
	}

	/**
	 * Show progress while executing a long-running operation
	 */
	export async function withProgress<T>(
		title: string,
		operation: (
			setMessage: (message: string) => void,
			token: vscode.CancellationToken
		) => Promise<T>
	): Promise<T> {
		return await ProgressIndicator.show(
			{
				title,
				cancellable: true
			},
			async (progress, token) => {
				return await operation(
					(message) => progress.report({ message }),
					token
				);
			}
		);
	}

	/**
	 * Show a loading spinner for a short duration
	 */
	export async function showLoading(
		title: string,
		durationMs = 1000
	): Promise<void> {
		await ProgressIndicator.showSimpleMessage(title, 'Loading...', durationMs);
	}

	/**
	 * Show progress with stages
	 */
	export async function showStagedProgress<T>(
		title: string,
		stages: Array<{
			name: string;
			task: (progress: (message: string) => void, token: vscode.CancellationToken) => Promise<T>;
		}>
	): Promise<T[]> {
		const results: T[] = [];

		await ProgressIndicator.show(
			{
				title,
				cancellable: true
			},
			async (progress, token) => {
				for (let i = 0; i < stages.length; i++) {
					if (token.isCancellationRequested) {
						throw new Error('Operation cancelled');
					}

					const stage = stages[i];
					progress.report({ message: `Stage ${i + 1}/${stages.length}: ${stage.name}` });

					const result = await stage.task(
						(message) => progress.report({ message: `${stage.name}: ${message}` }),
						token
					);
					results.push(result);
				}
			}
		);

		return results;
	}
}
