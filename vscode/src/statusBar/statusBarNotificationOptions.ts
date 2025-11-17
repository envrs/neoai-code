import { window, workspace } from "vscode";
import { completionsState } from "../state/completionsState";
import { sendEvent } from "../binary/requests/sendEvent";

const RESUME_NEOAI = "Resume Neoai";

export function showStatusBarNotificationOptions(
  settingsButton: string,
  onSettingsClicked: () => void
) {
  const snoozeDuration = workspace
    .getConfiguration("neoai")
    .get<number>("snoozeDuration", 1);

  const snoozeNeoai = `Snooze Neoai (${snoozeDuration}h)`;

  const currentAction = completionsState.value ? snoozeNeoai : RESUME_NEOAI;

  void window
    .showInformationMessage("Neoai options", settingsButton, currentAction)
    .then((selection) => {
      switch (selection) {
        case settingsButton:
          onSettingsClicked();
          break;
        case snoozeNeoai:
          trackSnoozeToggled(false, snoozeDuration);
          completionsState.value = false;
          break;
        case RESUME_NEOAI:
          trackSnoozeToggled(true, snoozeDuration);
          completionsState.value = true;
          break;
        default:
          console.warn("Unexpected selection");
          break;
      }
    });
}

function trackSnoozeToggled(showCompletions: boolean, duration: number) {
  void sendEvent({
    name: "snooze-toggled",
    properties: {
      show_completions: showCompletions.toString(),
      duration: duration.toString(),
    },
  });
}
