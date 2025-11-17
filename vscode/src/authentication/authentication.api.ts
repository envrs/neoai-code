import { neoAiProcess } from "../binary/requests/requests";
import { openExternalLogin } from "../cloudEnvs/openLogin";
import isCloudEnv from "../cloudEnvs/isCloudEnv";
import neoaiExtensionProperties from "../globals/neoaiExtensionProperties";
import { notifyOnError } from "../utils/notifyOnError";

export async function callForLogin(): Promise<void> {
  return notifyOnError(async () => {
    if (isCloudEnv || neoaiExtensionProperties.isRemote) {
      await openExternalLogin();
    }
    await neoAiProcess.request({ Login: {} });
  }, "Failed to call for login");
}

export async function callForLogout(): Promise<unknown> {
  return notifyOnError(
    () => neoAiProcess.request({ Logout: {} }),
    "Failed to call for logout"
  );
}

export async function signInUsingCustomToken(
  customToken: string
): Promise<unknown> {
  return notifyOnError(
    () =>
      neoAiProcess.request({
        LoginWithCustomToken: { custom_token: customToken },
      }),
    "Failed to sign in using custom token"
  );
}

export async function signInUsingCustomTokenUrl(): Promise<
  string | null | undefined
> {
  return notifyOnError(
    () =>
      neoAiProcess.request({
        LoginWithCustomTokenUrl: {},
      }),
    "Failed to sign in using custom token url"
  );
}
