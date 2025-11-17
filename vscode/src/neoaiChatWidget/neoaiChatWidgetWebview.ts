import * as vscode from "vscode";
import { ExtensionContext } from "vscode";
import ChatViewProvider from "./ChatViewProvider";
import { getState } from "../binary/requests/requests";
import { Logger } from "../utils/logger";
import { registerChatQuickFix } from "./extensionCommands/quickFix";
import registerChatCodeLens from "./extensionCommands/codeLens";
import ChatEnabledState, { ChatNotEnabledReason } from "./ChatEnabledState";

const VIEW_ID = "neoai.chat";

export default function registerNeoaiChatWidgetWebview(
  context: ExtensionContext,
  chatEnabledState: ChatEnabledState,
  chatProvider: ChatViewProvider
): void {
  if (process.env.IS_EVAL_MODE === "true") {
    void vscode.commands.executeCommand(
      "setContext",
      "neoai.chat.eval",
      true
    );
  }

  setNeoaiChatWebview("loading");

  context.subscriptions.push(
    chatEnabledState.onChange((state) => {
      if (state.enabled) {
        registerChatView(context, chatProvider);
      } else if (state.chatNotEnabledReason) {
        setContextForChatNotEnabled(state.chatNotEnabledReason);
      }
    })
  );
}

function setContextForChatNotEnabled(reason: ChatNotEnabledReason) {
  setChatReady(false);
  setNeoaiChatWebview(reason);
}

let hasRegisteredChatWebview = false;

function registerChatView(
  context: vscode.ExtensionContext,
  chatProvider: ChatViewProvider
) {
  if (!hasRegisteredChatWebview) {
    registerWebview(context, chatProvider);
  }

  setNeoaiChatWebview("chat");
  setChatReady(true);

  getState()
    .then((state) => {
      void vscode.commands.executeCommand(
        "setContext",
        "neoai.chat.settings-ready",
        state?.service_level !== "Business"
      );
    })
    .catch((e) => Logger.error(`Failed to get the user state ${e}`));
}

function registerWebview(
  context: ExtensionContext,
  chatProvider: ChatViewProvider
): void {
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(VIEW_ID, chatProvider, {
      webviewOptions: {
        retainContextWhenHidden: true, // keeps the state of the webview even when it's not visible
      },
    })
  );

  const evalCommands =
    process.env.IS_EVAL_MODE === "true"
      ? [
          vscode.commands.registerCommand(
            "neoai.chat.submit-message",
            (message: string) => {
              void chatProvider.handleMessageSubmitted(message);
            }
          ),
          vscode.commands.registerCommand(
            "neoai.chat.clear-all-conversations",
            () => {
              chatProvider.clearAllConversations();
            }
          ),
        ]
      : [];

  context.subscriptions.push(
    ...evalCommands,
    vscode.commands.registerCommand("neoai.chat.focus-input", () => {
      void chatProvider.focusChatInput();
    }),
    vscode.commands.registerCommand("neoai.chat.commands.explain-code", () =>
      chatProvider.handleMessageSubmitted("/explain-code")
    ),
    vscode.commands.registerCommand(
      "neoai.chat.commands.generate-tests",
      () => chatProvider.handleMessageSubmitted("/generate-test-for-code")
    ),
    vscode.commands.registerCommand("neoai.chat.commands.document-code", () =>
      chatProvider.handleMessageSubmitted("/document-code")
    ),
    vscode.commands.registerCommand("neoai.chat.commands.fix-code", () =>
      chatProvider.handleMessageSubmitted("/fix-code")
    )
  );
  registerChatQuickFix(context, chatProvider);
  registerChatCodeLens(context, chatProvider);

  hasRegisteredChatWebview = true;
}

function setNeoaiChatWebview(
  webviewName: ChatNotEnabledReason | "chat" | "loading"
) {
  void vscode.commands.executeCommand(
    "setContext",
    "neoai.chat.webview",
    webviewName
  );
}

function setChatReady(ready: boolean) {
  void vscode.commands.executeCommand(
    "setContext",
    "neoai.chat.ready",
    ready
  );
}
