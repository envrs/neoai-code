import * as vscode from 'vscode';
import { AssistantConfig, DEFAULT_CONFIG, AssistantMode } from './globals';

/**
 * Settings manager for NeoAI Assistant
 */

export interface SettingsSection {
	[key: string]: any;
}

export class SettingsManager {
	private static readonly SECTION_NAME = 'neoai';
	private static instance: SettingsManager;
	private config: AssistantConfig = { ...DEFAULT_CONFIG };
	private _onDidChange: vscode.EventEmitter<AssistantConfig> = new vscode.EventEmitter<AssistantConfig>();
	public readonly onDidChange: vscode.Event<AssistantConfig> = this._onDidChange.event;

	private constructor() {
		this.loadConfiguration();
		this.setupConfigurationListener();
	}

	static getInstance(): SettingsManager {
		if (!SettingsManager.instance) {
			SettingsManager.instance = new SettingsManager();
		}
		return SettingsManager.instance;
	}

	private setupConfigurationListener(): void {
		vscode.workspace.onDidChangeConfiguration((event) => {
			if (event.affectsConfiguration(SettingsManager.SECTION_NAME)) {
				this.loadConfiguration();
				this._onDidChange.fire(this.config);
			}
		});
	}

	private loadConfiguration(): void {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		
		this.config = {
			enabled: config.get<boolean>('enabled', DEFAULT_CONFIG.enabled),
			mode: config.get<AssistantMode>('mode', DEFAULT_CONFIG.mode),
			threshold: config.get<number>('threshold', DEFAULT_CONFIG.threshold),
			debounceMs: config.get<number>('debounceMs', DEFAULT_CONFIG.debounceMs),
			maxSuggestions: config.get<number>('maxSuggestions', DEFAULT_CONFIG.maxSuggestions)
		};
	}

	getConfiguration(): AssistantConfig {
		return { ...this.config };
	}

	updateConfiguration(changes: Partial<AssistantConfig>): Promise<void> {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		const promises: Promise<unknown>[] = [];

		for (const [key, value] of Object.entries(changes)) {
			if (value !== undefined) {
				promises.push(config.update(key, value, vscode.ConfigurationTarget.Global));
			}
		}

		return Promise.all(promises).then(() => {});
	}

	isEnabled(): boolean {
		return this.config.enabled;
	}

	getMode(): AssistantMode {
		return this.config.mode;
	}

	getThreshold(): number {
		return this.config.threshold;
	}

	getDebounceMs(): number {
		return this.config.debounceMs;
	}

	getMaxSuggestions(): number {
		return this.config.maxSuggestions;
	}

	async setEnabled(enabled: boolean): Promise<void> {
		await this.updateConfiguration({ enabled });
	}

	async setMode(mode: AssistantMode): Promise<void> {
		await this.updateConfiguration({ mode });
	}

	async setThreshold(threshold: number): Promise<void> {
		await this.updateConfiguration({ threshold });
	}

	async setDebounceMs(debounceMs: number): Promise<void> {
		await this.updateConfiguration({ debounceMs });
	}

	async setMaxSuggestions(maxSuggestions: number): Promise<void> {
		await this.updateConfiguration({ maxSuggestions });
	}

	/**
	 * Get a specific setting value
	 */
	get<T>(key: string, defaultValue?: T): T {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		return config.get<T>(key, defaultValue as T);
	}

	/**
	 * Set a specific setting value
	 */
	async set(key: string, value: any, target = vscode.ConfigurationTarget.Global): Promise<void> {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		await config.update(key, value, target);
	}

	/**
	 * Get all settings as a plain object
	 */
	getAllSettings(): any {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		return config;
	}

	/**
	 * Reset all settings to defaults
	 */
	async resetToDefaults(): Promise<void> {
		await this.updateConfiguration(DEFAULT_CONFIG);
	}

	/**
	 * Export current settings to JSON
	 */
	exportSettings(): string {
		return JSON.stringify(this.config, null, 2);
	}

	/**
	 * Import settings from JSON
	 */
	async importSettings(jsonString: string): Promise<void> {
		try {
			const settings = JSON.parse(jsonString);
			const validConfig = this.validateConfiguration(settings);
			await this.updateConfiguration(validConfig);
		} catch (error) {
			throw new Error(`Failed to import settings: ${error instanceof Error ? error.message : 'Unknown error'}`);
		}
	}

	/**
	 * Validate configuration object
	 */
	private validateConfiguration(config: any): AssistantConfig {
		const result: Partial<AssistantConfig> = {};

		if (typeof config.enabled === 'boolean') {
			result.enabled = config.enabled;
		}

		if (Object.values(AssistantMode).includes(config.mode)) {
			result.mode = config.mode as AssistantMode;
		}

		if (typeof config.threshold === 'number' && config.threshold >= 0 && config.threshold <= 1) {
			result.threshold = config.threshold;
		}

		if (typeof config.debounceMs === 'number' && config.debounceMs >= 0) {
			result.debounceMs = config.debounceMs;
		}

		if (typeof config.maxSuggestions === 'number' && config.maxSuggestions >= 0) {
			result.maxSuggestions = config.maxSuggestions;
		}

		return { ...DEFAULT_CONFIG, ...result } as AssistantConfig;
	}

	/**
	 * Check if a setting exists
	 */
	has(key: string): boolean {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		return config.has(key);
	}

	/**
	 * Get workspace-specific settings
	 */
	getWorkspaceSettings(): AssistantConfig {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		const workspaceConfig: Partial<AssistantConfig> = {};

		// Check each setting if it has a workspace value
		const inspect = config.inspect('enabled');
		if (inspect?.workspaceValue !== undefined) {
			workspaceConfig.enabled = inspect.workspaceValue as boolean;
		}

		const modeInspect = config.inspect('mode');
		if (modeInspect?.workspaceValue !== undefined) {
			workspaceConfig.mode = modeInspect?.workspaceValue as AssistantMode;
		}

		const thresholdInspect = config.inspect('threshold');
		if (thresholdInspect?.workspaceValue !== undefined) {
			workspaceConfig.threshold = thresholdInspect.workspaceValue as number;
		}

		const debounceInspect = config.inspect('debounceMs');
		if (debounceInspect?.workspaceValue !== undefined) {
			workspaceConfig.debounceMs = debounceInspect.workspaceValue as number;
		}

		const maxSuggestionsInspect = config.inspect('maxSuggestions');
		if (maxSuggestionsInspect?.workspaceValue !== undefined) {
			workspaceConfig.maxSuggestions = maxSuggestionsInspect.workspaceValue as number;
		}

		return { ...DEFAULT_CONFIG, ...workspaceConfig };
	}

	/**
	 * Get user-specific settings
	 */
	getUserSettings(): AssistantConfig {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		const userConfig: Partial<AssistantConfig> = {};

		// Check each setting if it has a user value
		const inspect = config.inspect('enabled');
		if (inspect?.globalValue !== undefined) {
			userConfig.enabled = inspect.globalValue as boolean;
		}

		const modeInspect = config.inspect('mode');
		if (modeInspect?.globalValue !== undefined) {
			userConfig.mode = modeInspect.globalValue as AssistantMode;
		}

		const thresholdInspect = config.inspect('threshold');
		if (thresholdInspect?.globalValue !== undefined) {
			userConfig.threshold = thresholdInspect.globalValue as number;
		}

		const debounceInspect = config.inspect('debounceMs');
		if (debounceInspect?.globalValue !== undefined) {
			userConfig.debounceMs = debounceInspect.globalValue as number;
		}

		const maxSuggestionsInspect = config.inspect('maxSuggestions');
		if (maxSuggestionsInspect?.globalValue !== undefined) {
			userConfig.maxSuggestions = maxSuggestionsInspect.globalValue as number;
		}

		return { ...DEFAULT_CONFIG, ...userConfig };
	}

	/**
	 * Watch for setting changes
	 */
	watchSetting(key: string, callback: (newValue: any, oldValue: any) => void): vscode.Disposable {
		let lastValue = this.get(key);

		return vscode.workspace.onDidChangeConfiguration((event) => {
			if (event.affectsConfiguration(`${SettingsManager.SECTION_NAME}.${key}`)) {
				const newValue = this.get(key);
				if (newValue !== lastValue) {
					callback(newValue, lastValue);
					lastValue = newValue;
				}
			}
		});
	}

	/**
	 * Create a setting with validation
	 */
	async createSettingWithValidation<T>(
		key: string,
		value: T,
		validator: (value: T) => boolean,
		target = vscode.ConfigurationTarget.Global
	): Promise<void> {
		if (!validator(value)) {
			throw new Error(`Invalid value for setting ${key}`);
		}

		await this.set(key, value, target);
	}

	/**
	 * Get setting with type safety
	 */
	getWithDefault<T>(key: string, defaultValue: T): T {
		return this.get<T>(key, defaultValue);
	}

	/**
	 * Batch update multiple settings
	 */
	async batchUpdate(settings: Record<string, any>, target = vscode.ConfigurationTarget.Global): Promise<void> {
		const config = vscode.workspace.getConfiguration(SettingsManager.SECTION_NAME);
		const promises: Promise<unknown>[] = [];

		for (const [key, value] of Object.entries(settings)) {
			promises.push(config.update(key, value, target));
		}

		await Promise.all(promises);
	}

	/**
	 * Check if settings are different from defaults
	 */
	hasCustomSettings(): boolean {
		return JSON.stringify(this.config) !== JSON.stringify(DEFAULT_CONFIG);
	}

	/**
	 * Get settings summary for display
	 */
	getSettingsSummary(): string {
		return `
NeoAI Assistant Settings:
- Enabled: ${this.config.enabled}
- Mode: ${this.config.mode}
- Threshold: ${this.config.threshold}
- Debounce: ${this.config.debounceMs}ms
- Max Suggestions: ${this.config.maxSuggestions}
		`.trim();
	}
}

/**
 * Utility functions for settings management
 */
export namespace SettingsUtils {
	/**
	 * Get the settings manager instance
	 */
	export function getSettingsManager(): SettingsManager {
		return SettingsManager.getInstance();
	}

	/**
	 * Create a quick pick for changing settings
	 */
	export async function showSettingsQuickPick(): Promise<void> {
		const settingsManager = getSettingsManager();
		const options = [
			{ label: 'Toggle Enabled', description: 'Enable or disable NeoAI Assistant' },
			{ label: 'Change Mode', description: 'Switch between assistant modes' },
			{ label: 'Adjust Threshold', description: 'Set suggestion confidence threshold' },
			{ label: 'Set Debounce Time', description: 'Configure response delay' },
			{ label: 'Max Suggestions', description: 'Set maximum number of suggestions' },
			{ label: 'Reset to Defaults', description: 'Reset all settings to default values' }
		];

		const choice = await vscode.window.showQuickPick(options, {
			placeHolder: 'Select a setting to modify'
		});

		if (!choice) {
			return;
		}

		switch (choice.label) {
			case 'Toggle Enabled':
				await settingsManager.setEnabled(!settingsManager.isEnabled());
				break;

			case 'Change Mode':
				await showModeSelector();
				break;

			case 'Adjust Threshold':
				await showThresholdInput();
				break;

			case 'Set Debounce Time':
				await showDebounceInput();
				break;

			case 'Max Suggestions':
				await showMaxSuggestionsInput();
				break;

			case 'Reset to Defaults':
				await settingsManager.resetToDefaults();
				break;
		}
	}

	async function showModeSelector(): Promise<void> {
		const settingsManager = getSettingsManager();
		const modes = Object.values(AssistantMode);
		const currentMode = settingsManager.getMode();

		const choice = await vscode.window.showQuickPick(modes, {
			placeHolder: `Current mode: ${currentMode}`
		});

		if (choice && choice !== currentMode) {
			await settingsManager.setMode(choice);
		}
	}

	async function showThresholdInput(): Promise<void> {
		const settingsManager = getSettingsManager();
		const currentThreshold = settingsManager.getThreshold();

		const value = await vscode.window.showInputBox({
			prompt: 'Enter confidence threshold (0.0 - 1.0)',
			value: currentThreshold.toString(),
			validateInput: (input) => {
				const num = parseFloat(input);
				if (isNaN(num) || num < 0 || num > 1) {
					return 'Please enter a number between 0.0 and 1.0';
				}
				return null;
			}
		});

		if (value) {
			await settingsManager.setThreshold(parseFloat(value));
		}
	}

	async function showDebounceInput(): Promise<void> {
		const settingsManager = getSettingsManager();
		const currentDebounce = settingsManager.getDebounceMs();

		const value = await vscode.window.showInputBox({
			prompt: 'Enter debounce time in milliseconds',
			value: currentDebounce.toString(),
			validateInput: (input) => {
				const num = parseInt(input);
				if (isNaN(num) || num < 0) {
					return 'Please enter a positive number';
				}
				return null;
			}
		});

		if (value) {
			await settingsManager.setDebounceMs(parseInt(value));
		}
	}

	async function showMaxSuggestionsInput(): Promise<void> {
		const settingsManager = getSettingsManager();
		const currentMax = settingsManager.getMaxSuggestions();

		const value = await vscode.window.showInputBox({
			prompt: 'Enter maximum number of suggestions',
			value: currentMax.toString(),
			validateInput: (input) => {
				const num = parseInt(input);
				if (isNaN(num) || num < 0) {
					return 'Please enter a positive number';
				}
				return null;
			}
		});

		if (value) {
			await settingsManager.setMaxSuggestions(parseInt(value));
		}
	}
}
