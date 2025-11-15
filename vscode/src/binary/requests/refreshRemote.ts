import { neoAiProcess } from "./requests";

export type RefreshResponse = {
  is_successful: boolean;
  error?: string;
};

export function refreshRemote(): Promise<RefreshResponse | null | undefined> {
  return neoAiProcess.request<RefreshResponse>({
    RefreshRemoteProperties: {},
  });
}
