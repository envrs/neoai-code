import * as path from "path";
import * as os from "os";

export const NEOAI_CONFIG_DIR = path.join(os.homedir(), ".config", "NeoAi");

export const NEOAI_TOKEN_FILE_NAME = ".refresh_token_v2";

export const NEOAI_TOKEN_FILE_PATH = path.join(
  NEOAI_CONFIG_DIR,
  NEOAI_TOKEN_FILE_NAME
);

export const NEOAI_CONFIG_FILE_NAME = "neoai_config.json";

export const NEOAI_CONFIG_FILE_PATH = path.join(
  NEOAI_CONFIG_DIR,
  NEOAI_CONFIG_FILE_NAME
);

export const NEOAI_TOKEN_CONTEXT_KEY = "NEOAI_TOKEN_V2";

export const NEOAI_CONFIG_CONTEXT_KEY = "NEOAI_CONFIG";
