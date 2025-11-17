import { neoAiProcess } from "./requests";

export interface Workspace {
  root_paths: string[];
}

export default function sendUpdateWorkspaceRequest(
  request: Workspace
): Promise<unknown | undefined | null> {
  return neoAiProcess.request<unknown, { Workspace: Workspace }>({
    Workspace: request,
  });
}
