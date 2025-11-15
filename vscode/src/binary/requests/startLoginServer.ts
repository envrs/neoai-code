import { neoAiProcess } from "./requests";

export function startLoginServer(): Promise<string | null | undefined> {
  return neoAiProcess.request(
    {
      StartLoginServer: {},
    },
    5000
  );
}
