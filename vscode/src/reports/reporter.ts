import { ExtensionMode } from "vscode";
import TelemetryReporter from "./TelemetryReporter";
import EventName from "./EventName";
import LogReporter from "./LogReporter";
import { INSTRUMENTATION_KEY } from "../globals/consts";
import neoaiExtensionProperties from "../globals/neoaiExtensionProperties";
import { getNeoaiExtensionContext } from "../globals/neoaiExtensionContext";

let innerReporter: TelemetryReporter | LogReporter;

export function initReporter(reporter?: TelemetryReporter | LogReporter) {
  innerReporter = reporter ?? setDefaultReporter();
}

function setDefaultReporter() {
  let reporter = new LogReporter();
  const context = getNeoaiExtensionContext();

  if (context.extensionMode !== ExtensionMode.Test) {
    reporter = new TelemetryReporter(
      neoaiExtensionProperties.id || "",
      neoaiExtensionProperties.version || "",
      INSTRUMENTATION_KEY
    );
    context.subscriptions.push(reporter);
  }
  return reporter;
}

export function report(event: EventName): void {
  innerReporter.report(event);
}

export function reportErrorEvent(event: EventName, error: Error): void {
  innerReporter.reportErrorEvent(event, error);
}
export function reportException(error: Error): void {
  innerReporter.reportException(error);
}
