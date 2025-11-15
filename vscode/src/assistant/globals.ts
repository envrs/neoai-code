/**
 * Global constants and utilities for the NeoAI Assistant
 */

export const ASSISTANT_NAME = 'NeoAI Assistant';
export const ASSISTANT_VERSION = '1.0.0';

export enum AssistantMode {
	Off = 'off',
	Inline = 'inline',
	Chat = 'chat',
	Full = 'full'
}

export enum DiagnosticSeverity {
	Error = 'error',
	Warning = 'warning',
	Information = 'info',
	Hint = 'hint'
}

export interface AssistantConfig {
	enabled: boolean;
	mode: AssistantMode;
	threshold: number;
	debounceMs: number;
	maxSuggestions: number;
}

export const DEFAULT_CONFIG: AssistantConfig = {
	enabled: true,
	mode: AssistantMode.Inline,
	threshold: 0.5,
	debounceMs: 200,
	maxSuggestions: 5
};

// Global state
let globalConfig: AssistantConfig = { ...DEFAULT_CONFIG };
let isEnabled: boolean = true;

export function getConfig(): AssistantConfig {
	return { ...globalConfig };
}

export function updateConfig(config: Partial<AssistantConfig>): void {
	globalConfig = { ...globalConfig, ...config };
}

export function isAssistantEnabled(): boolean {
	return isEnabled && globalConfig.enabled;
}

export function setAssistantEnabled(enabled: boolean): void {
	isEnabled = enabled;
}

export function getAssistantThreshold(): number {
	return globalConfig.threshold;
}

export function setAssistantThreshold(threshold: number): void {
	if (threshold >= 0 && threshold <= 1) {
		globalConfig.threshold = threshold;
	}
}