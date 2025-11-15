import { AssistantMode } from './globals';
import * as vscode from 'vscode';

/**
 * Assistant mode management for NeoAI Assistant
 */

export interface AssistantModeConfig {
	mode: AssistantMode;
	enabled: boolean;
	features: AssistantFeatures;
}

export interface AssistantFeatures {
	inlineCompletions: boolean;
	codeActions: boolean;
	diagnostics: boolean;
	chat: boolean;
	explanations: boolean;
	testGeneration: boolean;
	documentation: boolean;
	codeFixing: boolean;
}

export const DEFAULT_FEATURES: AssistantFeatures = {
	inlineCompletions: true,
	codeActions: true,
	diagnostics: true,
	chat: false,
	explanations: true,
	testGeneration: true,
	documentation: true,
	codeFixing: true
};

export class AssistantModeManager {
	private currentMode: AssistantMode;
	private config: AssistantModeConfig;

	constructor() {
		this.currentMode = AssistantMode.Inline;
		this.config = {
			mode: this.currentMode,
			enabled: true,
			features: { ...DEFAULT_FEATURES }
		};
	}

	getCurrentMode(): AssistantMode {
		return this.currentMode;
	}

	setMode(mode: AssistantMode): void {
		this.currentMode = mode;
		this.config.mode = mode;
		this.updateFeaturesForMode(mode);
	}

	getConfig(): AssistantModeConfig {
		return { ...this.config };
	}

	updateConfig(config: Partial<AssistantModeConfig>): void {
		this.config = { ...this.config, ...config };
		if (config.mode) {
			this.currentMode = config.mode;
			this.updateFeaturesForMode(config.mode);
		}
	}

	isFeatureEnabled(feature: keyof AssistantFeatures): boolean {
		return this.config.enabled && this.config.features[feature];
	}

	getEnabledFeatures(): AssistantFeatures {
		if (!this.config.enabled) {
			return Object.keys(DEFAULT_FEATURES).reduce((acc, key) => {
				acc[key as keyof AssistantFeatures] = false;
				return acc;
			}, {} as AssistantFeatures);
		}
		return { ...this.config.features };
	}

	private updateFeaturesForMode(mode: AssistantMode): void {
		switch (mode) {
			case AssistantMode.Off:
				this.config.features = Object.keys(DEFAULT_FEATURES).reduce((acc, key) => {
					acc[key as keyof AssistantFeatures] = false;
					return acc;
				}, {} as AssistantFeatures);
				break;

			case AssistantMode.Inline:
				this.config.features = {
					...DEFAULT_FEATURES,
					chat: false,
					explanations: false
				};
				break;

			case AssistantMode.Chat:
				this.config.features = {
					...DEFAULT_FEATURES,
					inlineCompletions: false,
					codeActions: false,
					diagnostics: false
				};
				break;

			case AssistantMode.Full:
				this.config.features = { ...DEFAULT_FEATURES };
				break;
		}
	}

	enable(): void {
		this.config.enabled = true;
	}

	disable(): void {
		this.config.enabled = false;
	}

	toggle(): boolean {
		this.config.enabled = !this.config.enabled;
		return this.config.enabled;
	}

	isEnabled(): boolean {
		return this.config.enabled;
	}

	getModeDescription(mode: AssistantMode): string {
		switch (mode) {
			case AssistantMode.Off:
				return 'NeoAI Assistant is disabled';
			case AssistantMode.Inline:
				return 'Inline completions and quick actions only';
			case AssistantMode.Chat:
				return 'Chat interface for code assistance';
			case AssistantMode.Full:
				return 'All NeoAI Assistant features enabled';
			default:
				return 'Unknown mode';
		}
	}

	getAvailableModes(): AssistantMode[] {
		return Object.values(AssistantMode);
	}

	async showModePicker(): Promise<AssistantMode | undefined> {
		const modes = this.getAvailableModes();
		const items = modes.map(mode => ({
			label: mode.charAt(0).toUpperCase() + mode.slice(1),
			description: this.getModeDescription(mode),
			mode
		}));

		// Since showQuickPick is not available, use showInformationMessage as fallback
		const modeLabels = items.map(item => item.label);
		const selected = await vscode.window.showInformationMessage(
			'Select NeoAI Assistant Mode:',
			...modeLabels
		);

		if (!selected) return undefined;

		const selectedItem = items.find(item => item.label === selected);
		return selectedItem?.mode;
	}
}

// Global instance
let modeManager: AssistantModeManager | undefined;

export function getModeManager(): AssistantModeManager {
	if (!modeManager) {
		modeManager = new AssistantModeManager();
	}
	return modeManager;
}

export function resetModeManager(): void {
	modeManager = undefined;
}

// Utility functions
export function isInlineCompletionsEnabled(): boolean {
	return getModeManager().isFeatureEnabled('inlineCompletions');
}

export function areCodeActionsEnabled(): boolean {
	return getModeManager().isFeatureEnabled('codeActions');
}

export function areDiagnosticsEnabled(): boolean {
	return getModeManager().isFeatureEnabled('diagnostics');
}

export function isChatEnabled(): boolean {
	return getModeManager().isFeatureEnabled('chat');
}

export function areExplanationsEnabled(): boolean {
	return getModeManager().isFeatureEnabled('explanations');
}

export function isTestGenerationEnabled(): boolean {
	return getModeManager().isFeatureEnabled('testGeneration');
}

export function isDocumentationEnabled(): boolean {
	return getModeManager().isFeatureEnabled('documentation');
}

export function isCodeFixingEnabled(): boolean {
	return getModeManager().isFeatureEnabled('codeFixing');
}