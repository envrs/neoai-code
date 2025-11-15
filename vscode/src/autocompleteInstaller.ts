import * as vscode from 'vscode';
import { ProgressIndicator, ProgressUtils } from './assistant/ProgressIndicator';

/**
 * Autocomplete installer for NeoAI Assistant
 */

export interface InstallOptions {
	version?: string;
	force?: boolean;
	skipValidation?: boolean;
	installPath?: string;
}

export interface InstallStatus {
	status: 'not-installed' | 'installing' | 'installed' | 'failed' | 'outdated';
	version?: string;
	latestVersion?: string;
	installPath?: string;
	lastChecked?: number;
	error?: string;
}

export interface InstallProgress {
	stage: string;
	progress: number;
	message: string;
}

export class AutocompleteInstaller {
	private static instance: AutocompleteInstaller;
	private status: InstallStatus = { status: 'not-installed' };
	private disposables: vscode.Disposable[] = [];
	private _onStatusChanged: vscode.EventEmitter<InstallStatus> = new vscode.EventEmitter<InstallStatus>();
	public readonly onStatusChanged: vscode.Event<InstallStatus> = this._onStatusChanged.event;

	private constructor() {
		this.checkInitialStatus();
	}

	static getInstance(): AutocompleteInstaller {
		if (!AutocompleteInstaller.instance) {
			AutocompleteInstaller.instance = new AutocompleteInstaller();
		}
		return AutocompleteInstaller.instance;
	}

	private async checkInitialStatus(): Promise<void> {
		try {
			await this.checkInstallStatus();
		} catch (error) {
			console.error('Failed to check initial install status:', error);
		}
	}

	async checkInstallStatus(): Promise<InstallStatus> {
		try {
			// Check if binary exists and is accessible
			const binaryPath = this.getBinaryPath();
			const exists = await this.checkBinaryExists(binaryPath);
			
			if (!exists) {
				this.updateStatus({ status: 'not-installed' });
				return this.status;
			}

			// Get version information
			const version = await this.getBinaryVersion(binaryPath);
			
			// Check for updates
			const latestVersion = await this.getLatestVersion();
			const isOutdated = latestVersion && version && this.compareVersions(version, latestVersion) < 0;

			this.updateStatus({
				status: isOutdated ? 'outdated' : 'installed',
				version,
				latestVersion,
				installPath: binaryPath,
				lastChecked: Date.now()
			});

			return this.status;
		} catch (error) {
			this.updateStatus({
				status: 'failed',
				error: error instanceof Error ? error.message : 'Unknown error'
			});
			return this.status;
		}
	}

	async install(options: InstallOptions = {}): Promise<void> {
		if (this.status.status === 'installing') {
			throw new Error('Installation is already in progress');
		}

		try {
			this.updateStatus({ status: 'installing' });

			await ProgressUtils.withProgress(
				'Installing NeoAI Autocomplete',
				async (setMessage, token) => {
					await this.performInstallation(options, setMessage, token);
				}
			);

			await this.checkInstallStatus();
		} catch (error) {
			this.updateStatus({
				status: 'failed',
				error: error instanceof Error ? error.message : 'Installation failed'
			});
			throw error;
		}
	}

	async uninstall(): Promise<void> {
		try {
			const binaryPath = this.getBinaryPath();
			
			if (await this.checkBinaryExists(binaryPath)) {
				await this.removeBinary(binaryPath);
			}

			this.updateStatus({ status: 'not-installed' });
		} catch (error) {
			this.updateStatus({
				status: 'failed',
				error: error instanceof Error ? error.message : 'Uninstallation failed'
			});
			throw error;
		}
	}

	async update(): Promise<void> {
		if (this.status.status !== 'outdated') {
			throw new Error('No update available');
		}

		await this.install({ force: true });
	}

	private async performInstallation(
		options: InstallOptions,
		setMessage: (message: string) => void,
		token: vscode.CancellationToken
	): Promise<void> {
		setMessage('Preparing installation...');
		
		if (token.isCancellationRequested) {
			throw new Error('Installation cancelled');
		}

		// Download binary
		setMessage('Downloading binary...');
		const version = options.version ?? (await this.getLatestVersion());
		const downloadUrl = this.getDownloadUrl(version);
		
		const binaryData = await this.downloadBinary(downloadUrl, token);
		
		if (token.isCancellationRequested) {
			throw new Error('Installation cancelled');
		}

		// Install binary
		setMessage('Installing binary...');
		const installPath = options.installPath ?? this.getDefaultInstallPath();
		await this.installBinary(binaryData, installPath);

		// Validate installation
		if (!options.skipValidation) {
			setMessage('Validating installation...');
			const isValid = await this.validateInstallation(installPath);
			
			if (!isValid) {
				throw new Error('Installation validation failed');
			}
		}

		setMessage('Installation complete');
	}

	private getBinaryPath(): string {
		// Implementation would get the actual binary path
		// This is a placeholder
		return vscode.workspace.getConfiguration('neoai').get('binaryPath', '') || 
			   this.getDefaultInstallPath();
	}

	private getDefaultInstallPath(): string {
		// Implementation would return the default install path
		// This is a placeholder
		const extensionPath = vscode.extensions.getExtension('neoai.neoai')?.extensionPath ?? '';
		return `${extensionPath}/bin/neoai-binary`;
	}

	private async checkBinaryExists(path: string): Promise<boolean> {
		try {
			// Implementation would check if binary exists
			// This is a placeholder
			return false;
		} catch {
			return false;
		}
	}

	private async getBinaryVersion(path: string): Promise<string | undefined> {
		try {
			// Implementation would get binary version
			// This is a placeholder
			return undefined;
		} catch {
			return undefined;
		}
	}

	private async getLatestVersion(): Promise<string | undefined> {
		try {
			// Implementation would fetch latest version from API
			// This is a placeholder
			return '1.0.0';
		} catch {
			return undefined;
		}
	}

	private compareVersions(version1: string, version2: string): number {
		const v1Parts = version1.split('.').map(Number);
		const v2Parts = version2.split('.').map(Number);
		
		for (let i = 0; i < Math.max(v1Parts.length, v2Parts.length); i++) {
			const v1Part = v1Parts[i] ?? 0;
			const v2Part = v2Parts[i] ?? 0;
			
			if (v1Part < v2Part) return -1;
			if (v1Part > v2Part) return 1;
		}
		
		return 0;
	}

	private getDownloadUrl(version: string): string {
		// Implementation would construct download URL
		// This is a placeholder
		return `https://releases.neoai.ai/v${version}/neoai-binary-${this.getPlatform()}.zip`;
	}

	private getPlatform(): string {
		const platform = process.platform;
		const arch = process.arch;
		
		switch (platform) {
			case 'darwin':
				return arch === 'arm64' ? 'darwin-arm64' : 'darwin-x64';
			case 'linux':
				return arch === 'arm64' ? 'linux-arm64' : 'linux-x64';
			case 'win32':
				return arch === 'arm64' ? 'win32-arm64' : 'win32-x64';
			default:
				return platform;
		}
	}

	private async downloadBinary(url: string, token: vscode.CancellationToken): Promise<Buffer> {
		// Implementation would download binary from URL
		// This is a placeholder
		throw new Error('Download not implemented');
	}

	private async installBinary(data: Buffer, path: string): Promise<void> {
		// Implementation would install binary to path
		// This is a placeholder
		throw new Error('Installation not implemented');
	}

	private async removeBinary(path: string): Promise<void> {
		// Implementation would remove binary
		// This is a placeholder
		throw new Error('Removal not implemented');
	}

	private async validateInstallation(path: string): Promise<boolean> {
		try {
			// Check if binary exists and is executable
			const exists = await this.checkBinaryExists(path);
			if (!exists) {
				return false;
			}

			// Try to get version
			const version = await this.getBinaryVersion(path);
			return !!version;
		} catch {
			return false;
		}
	}

	private updateStatus(newStatus: Partial<InstallStatus>): void {
		this.status = { ...this.status, ...newStatus };
		this._onStatusChanged.fire(this.status);
	}

	/**
	 * Get current installation status
	 */
	getStatus(): InstallStatus {
		return { ...this.status };
	}

	/**
	 * Check if installation is needed
	 */
	isInstallationNeeded(): boolean {
		return this.status.status === 'not-installed' || 
			   this.status.status === 'outdated' || 
			   this.status.status === 'failed';
	}

	/**
	 * Get installation information
	 */
	getInstallInfo(): {
		isInstalled: boolean;
		version?: string;
		latestVersion?: string;
		isOutdated: boolean;
		installPath?: string;
		error?: string;
	} {
		const isInstalled = this.status.status === 'installed' || this.status.status === 'outdated';
		const isOutdated = this.status.status === 'outdated';

		return {
			isInstalled,
			version: this.status.version,
			latestVersion: this.status.latestVersion,
			isOutdated,
			installPath: this.status.installPath,
			error: this.status.error
		};
	}

	/**
	 * Dispose of the installer
	 */
	dispose(): void {
		for (const disposable of this.disposables) {
			disposable.dispose();
		}
		this.disposables = [];
		this._onStatusChanged.dispose();
	}
}

/**
 * Utility functions for installation management
 */
export namespace InstallerUtils {
	/**
	 * Get the installer instance
	 */
	export function getInstaller(): AutocompleteInstaller {
		return AutocompleteInstaller.getInstance();
	}

	/**
	 * Show installation status in the status bar
	 */
	export function showInstallationStatus(): vscode.Disposable {
		const installer = getInstaller();
		const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right);

		const updateStatusBar = () => {
			const status = installer.getStatus();
			
			switch (status.status) {
				case 'installed':
					statusBarItem.text = `$(check) NeoAI ${status.version}`;
					statusBarItem.tooltip = 'NeoAI Assistant is installed and ready';
					statusBarItem.color = undefined;
					break;
				case 'outdated':
					statusBarItem.text = `$(alert) NeoAI ${status.version} → ${status.latestVersion}`;
					statusBarItem.tooltip = 'NeoAI Assistant update available';
					statusBarItem.color = new vscode.ThemeColor('statusBarItem.warningForeground');
					break;
				case 'installing':
					statusBarItem.text = '$(sync~spin) Installing NeoAI...';
					statusBarItem.tooltip = 'NeoAI Assistant is being installed';
					statusBarItem.color = new vscode.ThemeColor('statusBarItem.prominentForeground');
					break;
				case 'failed':
					statusBarItem.text = '$(error) NeoAI';
					statusBarItem.tooltip = `NeoAI Assistant installation failed: ${status.error}`;
					statusBarItem.color = new vscode.ThemeColor('statusBarItem.errorForeground');
					break;
				case 'not-installed':
				default:
					statusBarItem.text = '$(circle-outline) NeoAI';
					statusBarItem.tooltip = 'NeoAI Assistant is not installed';
					statusBarItem.color = undefined;
					break;
			}
		};

		updateStatusBar();
		statusBarItem.show();

		const disposable = installer.onStatusChanged(updateStatusBar);

		return {
			dispose: () => {
				disposable.dispose();
				statusBarItem.dispose();
			}
		};
	}

	/**
	 * Show installation quick pick
	 */
	export async function showInstallationQuickPick(): Promise<void> {
		const installer = getInstaller();
		const status = installer.getStatus();

		const options: vscode.QuickPickItem[] = [];

		if (status.status === 'not-installed' || status.status === 'failed') {
			options.push({
				label: '$(download) Install NeoAI Assistant',
				description: 'Download and install the NeoAI binary'
			});
		}

		if (status.status === 'installed' || status.status === 'outdated') {
			if (status.status === 'outdated') {
				options.push({
					label: '$(arrow-up) Update NeoAI Assistant',
					description: `Update from ${status.version} to ${status.latestVersion}`
				});
			}
			
			options.push({
				label: '$(trash) Uninstall NeoAI Assistant',
				description: 'Remove the NeoAI binary'
			});
		}

		options.push({
			label: '$(refresh) Check for Updates',
			description: 'Check if a new version is available'
		});

		const choice = await vscode.window.showQuickPick(options, {
			placeHolder: 'NeoAI Assistant Installation Options'
		});

		if (!choice) {
			return;
		}

		try {
			switch (choice.label) {
				case '$(download) Install NeoAI Assistant':
					await installer.install();
					vscode.window.showInformationMessage('NeoAI Assistant installed successfully!');
					break;

				case '$(arrow-up) Update NeoAI Assistant':
					await installer.update();
					vscode.window.showInformationMessage('NeoAI Assistant updated successfully!');
					break;

				case '$(trash) Uninstall NeoAI Assistant':
					const confirm = await vscode.window.showWarningMessage(
						'Are you sure you want to uninstall NeoAI Assistant?',
						'Uninstall',
						'Cancel'
					);
					
					if (confirm === 'Uninstall') {
						await installer.uninstall();
						vscode.window.showInformationMessage('NeoAI Assistant uninstalled successfully!');
					}
					break;

				case '$(refresh) Check for Updates':
					await installer.checkInstallStatus();
					const newStatus = installer.getStatus();
					
					if (newStatus.status === 'outdated') {
						vscode.window.showInformationMessage(
							`Update available: ${newStatus.version} → ${newStatus.latestVersion}`,
							'Update Now'
						).then(choice => {
							if (choice === 'Update Now') {
								installer.update();
							}
						});
					} else if (newStatus.status === 'installed') {
						vscode.window.showInformationMessage('NeoAI Assistant is up to date!');
					}
					break;
			}
		} catch (error) {
			vscode.window.showErrorMessage(
				`Failed to ${choice.label}: ${error instanceof Error ? error.message : 'Unknown error'}`
			);
		}
	}
}