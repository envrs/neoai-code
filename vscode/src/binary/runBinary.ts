import * as semver from "semver";
import * as vscode from "vscode";
import neoaiExtensionProperties from "../globals/neoaiExtensionProperties";
import fetchBinaryPath from "./binaryFetcher";
import { BinaryProcessRun, runProcess } from "./runProcess";
import { getCurrentVersion } from "../preRelease/versions";
import { getNeoaiExtensionContext } from "../globals/neoaiExtensionContext";
import { getProxySettings } from "../proxyProvider";
import { versionOfPath } from "./paths";
import { TLS_CONFIG_MIN_SUPPORTED_VERSION } from "../globals/consts";

export default async function runBinary(
  additionalArgs: string[] = [],
  inheritStdio = false
): Promise<BinaryProcessRun> {
  const [runArgs, metadata] = splitArgs(additionalArgs);
  const command = await fetchBinaryPath();
  const version = versionOfPath(command);
  const context = getNeoaiExtensionContext();
  const tlsConfig =
    version && semver.gte(version, TLS_CONFIG_MIN_SUPPORTED_VERSION)
      ? [
          "--tls_config",
          `insecure=${neoaiExtensionProperties.ignoreCertificateErrors}`,
        ]
      : [];
  const proxySettings = neoaiExtensionProperties.useProxySupport
    ? getProxySettings()
    : undefined;
  const args: string[] = [
    ...tlsConfig,
    "--no-lsp=true",
    neoaiExtensionProperties.logEngine ? `--log_to_stderr` : null,
    neoaiExtensionProperties.logFilePath
      ? `--log-file-path=${neoaiExtensionProperties.logFilePath}`
      : null,
    neoaiExtensionProperties.logLevel
      ? `--log-level=${neoaiExtensionProperties.logLevel}`
      : null,
    ...runArgs,
    "--client-metadata",
    `clientVersion=${neoaiExtensionProperties.vscodeVersion}`,
    `pluginVersion=${(context && getCurrentVersion(context)) || "unknown"}`,
    `t9-vscode-AutoImportEnabled=${neoaiExtensionProperties.isNeoAiAutoImportEnabled}`,
    `t9-vscode-TSAutoImportEnabled=${
      neoaiExtensionProperties.isTypeScriptAutoImports ?? "unknown"
    }`,
    `t9-vscode-JSAutoImportEnabled=${
      neoaiExtensionProperties.isJavaScriptAutoImports ?? "unknown"
    }`,
    `vscode-telemetry-enabled=${neoaiExtensionProperties.isVscodeTelemetryEnabled}`,
    `vscode-remote=${neoaiExtensionProperties.isRemote}`,
    neoaiExtensionProperties.remoteName
      ? `vscode-remote-name=${neoaiExtensionProperties.remoteName}`
      : null,
    `vscode-extension-kind=${neoaiExtensionProperties.extensionKind}`,
    `vscode-theme-name=${neoaiExtensionProperties.themeName ?? "unknown"}`,
    `vscode-theme-kind=${neoaiExtensionProperties.themeKind}`,
    `vscode-machine-id=${vscode.env.machineId}`,
    `vscode-is-new-app-install=${vscode.env.isNewAppInstall}`,
    `vscode-session-id=${vscode.env.sessionId}`,
    `vscode-language=${vscode.env.language}`,
    `vscode-app-name=${vscode.env.appName}`,
    `vscode-beta-channel-enabled=${neoaiExtensionProperties.isExtensionBetaChannelEnabled}`,
    `vscode-status-customization=${
      neoaiExtensionProperties.statusBarColorCustomizations ?? "unknown"
    }`,
    `vscode-inline-api-enabled=${
      neoaiExtensionProperties.isVscodeInlineAPIEnabled ?? "unknown"
    }`,
    `vscode-code-lens-enabled=${
      neoaiExtensionProperties.codeLensEnabled ?? "unknown"
    }`,
    `vscode-found-intellicode=${neoaiExtensionProperties.foundIntellicode}`,
    ...metadata,
  ].filter((i): i is string => i !== null);

  // we want to fix the binary version when running evaluation,
  // without the bootstrapper swapping versions underneath our feet.
  if (process.env.IS_EVAL_MODE) {
    args.push("--no_bootstrap");
  }

  return runProcess(command, args, {
    stdio: inheritStdio ? "inherit" : "pipe",
    env: {
      ...process.env,
      https_proxy: proxySettings,
      HTTPS_PROXY: proxySettings,
      http_proxy: proxySettings,
      HTTP_PROXY: proxySettings,
    },
  });
}
function splitArgs(args: string[]): [string[], string[]] {
  return args.reduce<[string[], string[]]>(
    (items, item: string) => {
      if (item.startsWith("--")) {
        items[0].push(item);
      } else {
        items[1].push(item);
      }
      return items;
    },
    [[], []]
  );
}
