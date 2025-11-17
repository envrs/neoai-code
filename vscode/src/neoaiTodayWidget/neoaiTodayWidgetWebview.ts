import { ExtensionContext } from "vscode";
import { fireEvent } from "../binary/requests/requests";
import { Capability } from "../capabilities/capabilities";
import { StateType } from "../globals/consts";
import registerWidgetWebviewProvider from "../widgetWebview/widgetWebview";
import { Logger } from "../utils/logger";

const LOADED_NEOAI_TODAY_WIDGET = "loaded-neoai-today-widget-as-webview";

export default function registerNeoaiTodayWidgetWebview(
  context: ExtensionContext
): void {
  registerWidgetWebviewProvider(context, {
    capability: Capability.NEOAI_TODAY_WIDGET,
    getHubBaseUrlSource: StateType.NEOAI_TODAY_WIDGET_WEBVIEW,
    hubPath: "/neoai-today-widget",
    readyCommand: "neoai.neoai-today-ready",
    viewId: "neoai-today",
    onWebviewLoaded: () => {
      void fireEvent({
        name: LOADED_NEOAI_TODAY_WIDGET,
      }).catch((e) => Logger.error(e));
    },
  });
}
