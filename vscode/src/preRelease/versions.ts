import * as semver from "semver";
import {
  ALPHA_VERSION_KEY,
  MINIMAL_SUPPORTED_VSCODE_API,
} from "../globals/consts";
import neoaiExtensionProperties from "../globals/neoaiExtensionProperties";
import { ExtensionContext } from "./types";

export function getCurrentVersion(
  context: ExtensionContext
): string | undefined {
  const persistedAlphaVersion = getPersistedAlphaVersion(context);
  return persistedAlphaVersion || neoaiExtensionProperties.version;
}

export function getPersistedAlphaVersion(
  context: ExtensionContext
): string | undefined {
  return context.globalState.get<string | undefined>(ALPHA_VERSION_KEY);
}

export function updatePersistedAlphaVersion(
  context: ExtensionContext,
  installedVersion: string | undefined
): Thenable<void> {
  return context.globalState.update(ALPHA_VERSION_KEY, installedVersion);
}

export function getAvailableAlphaVersion(artifactUrl: string): string {
  const versionPattern = /(?<=download\/)(.*)(?=\/neoai-vscode)/gi;
  const match = artifactUrl.match(versionPattern);
  return (match && match[0]) || "";
}

export function isPreReleaseChannelSupported(): boolean {
  return semver.gte(
    neoaiExtensionProperties.vscodeVersion,
    MINIMAL_SUPPORTED_VSCODE_API
  );
}
