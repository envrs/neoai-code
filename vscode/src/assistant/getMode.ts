import { AssistantModeManager } from './AssistantMode';

export function getMode(): AssistantModeManager {
  return AssistantModeManager.getInstance();
}

export function isModeEnabled(mode: string): boolean {
  const modeManager = getMode();
  return modeManager.isFeatureEnabled(mode);
}