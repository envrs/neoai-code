import { URL } from "url";
import { Uri } from "vscode";
import {
  NEOAI_RETURN_URL_QUERY_PARAM,
  NEOAI_URL_QUERY_PARAM,
} from "../globals/consts";
import { asExternalUri } from "./asExternalUri";

export async function asExternal(url: string, path?: string) {
  const serviceUrl = new URL(url);

  const neoaiUrl = serviceUrl.searchParams.get(NEOAI_URL_QUERY_PARAM);
  const returnUrl = serviceUrl.searchParams.get(NEOAI_RETURN_URL_QUERY_PARAM);

  if (neoaiUrl) {
    serviceUrl.searchParams.set(
      NEOAI_URL_QUERY_PARAM,
      (await asExternalUri(Uri.parse(neoaiUrl))).toString()
    );
  }

  if (returnUrl) {
    serviceUrl.searchParams.set(
      NEOAI_RETURN_URL_QUERY_PARAM,
      (await asExternalUri(Uri.parse(returnUrl))).toString()
    );
  }

  let parsedUri = Uri.parse(serviceUrl.toString());

  if (path) {
    parsedUri = Uri.joinPath(parsedUri, path);
  }

  return asExternalUri(parsedUri);
}
