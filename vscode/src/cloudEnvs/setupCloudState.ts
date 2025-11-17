import { promises as fsPromises } from "fs";
import { ExtensionContext } from "vscode";
import * as consts from "./consts";
import { ensureExists, watch } from "../utils/file.utils";
import { Logger } from "../utils/logger";

export default async function state(context: ExtensionContext): Promise<void> {
  await ensureExists(consts.NEOAI_CONFIG_DIR);

  context.globalState.setKeysForSync([
    consts.NEOAI_TOKEN_CONTEXT_KEY,
    consts.NEOAI_CONFIG_CONTEXT_KEY,
  ]);

  await loadStateFromCloudEnv(context);
  persistStateToCloudEnv(context);
}

async function loadStateFromCloudEnv(context: ExtensionContext): Promise<void> {
  const neoaiToken = context.globalState.get<string>(
    consts.NEOAI_TOKEN_CONTEXT_KEY
  );

  const neoaiConfig = context.globalState.get<string>(
    consts.NEOAI_CONFIG_CONTEXT_KEY
  );

  if (neoaiToken) {
    await fsPromises
      .writeFile(consts.NEOAI_TOKEN_FILE_PATH, neoaiToken)
      .catch((e) => {
        Logger.error("Error occurred while trying to load Neoai token", e);
      });
  }

  if (neoaiConfig)
    await fsPromises
      .writeFile(consts.NEOAI_CONFIG_FILE_PATH, neoaiConfig)
      .catch((e) => {
        Logger.error("Error occurred while trying to load Neoai config", e);
      });
}

function persistStateToCloudEnv(context: ExtensionContext): void {
  watch(consts.NEOAI_CONFIG_DIR, (event, filename) => {
    switch (filename) {
      case consts.NEOAI_TOKEN_FILE_NAME:
        if (event === "rename") {
          void context.globalState.update(
            consts.NEOAI_TOKEN_CONTEXT_KEY,
            undefined
          );
        } else {
          void fsPromises
            .readFile(consts.NEOAI_TOKEN_FILE_PATH, "utf8")
            .then((neoaiToken) =>
              context.globalState.update(
                consts.NEOAI_TOKEN_CONTEXT_KEY,
                neoaiToken
              )
            )
            .catch((e) => {
              Logger.error(
                "Error occurred while trying to persist Neoai token",
                e
              );
            });
        }
        break;
      case consts.NEOAI_CONFIG_FILE_NAME:
        void fsPromises
          .readFile(consts.NEOAI_CONFIG_FILE_PATH, "utf8")
          .then((neoaiConfig) =>
            context.globalState.update(
              consts.NEOAI_CONFIG_CONTEXT_KEY,
              neoaiConfig
            )
          )
          .catch((e) => {
            Logger.error(
              "Error occurred while trying to persist Neoai config",
              e
            );
          });
        break;
      default:
    }
  });
}
