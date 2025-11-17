import * as semver from "semver";
import neoaiExtensionProperties from "./neoaiExtensionProperties";

const AUTHENTICATION_API_VERSION = "1.54.0";
const INLINE_API_PROPOSED_VERSION = "1.58.0";
const INLINE_API_RELEASE_VERSION = "1.68.0";

export default function isAuthenticationApiSupported(): boolean {
  return semver.gte(
    neoaiExtensionProperties.vscodeVersion,
    AUTHENTICATION_API_VERSION
  );
}

export function isInlineSuggestionProposedApiSupported(): boolean {
  return semver.gte(
    neoaiExtensionProperties.vscodeVersion,
    INLINE_API_PROPOSED_VERSION
  );
}
export function isInlineSuggestionReleasedApiSupported(): boolean {
  return semver.gte(
    neoaiExtensionProperties.vscodeVersion,
    INLINE_API_RELEASE_VERSION
  );
}
