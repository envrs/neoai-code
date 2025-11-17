import { Logger } from "../../utils/logger";
import { neoAiProcess } from "./requests";

interface NotifyWorkspaceChangedRequest {
  NotifyWorkspaceChanged: {
    workspace_folders: string[];
  };
}

function notifyWorkspaceChanged(
  workspaceFolders: string[]
): Promise<void | null | undefined> {
  return neoAiProcess
    .request<null, NotifyWorkspaceChangedRequest>(
      {
        NotifyWorkspaceChanged: { workspace_folders: workspaceFolders },
      },
      5000
    )
    .catch((e) => Logger.error(e));
}

export default notifyWorkspaceChanged;
