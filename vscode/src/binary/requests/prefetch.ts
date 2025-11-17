import { neoAiProcess } from "./requests";

export type PrefetchRequest = {
  filename: string;
};

export function prefetch(
  prefetchReuqest: PrefetchRequest
): Promise<void | null | undefined> {
  return neoAiProcess.request<void>({ Prefetch: prefetchReuqest });
}
