import { MessageAction } from "../../globals/consts";
import { neoAiProcess } from "./requests";

export type Hover = {
  id: string;
  message: string;
  title: string;
  options: {
    key: string;
    actions: MessageAction[];
  }[];
  notification_type: unknown;
  state: unknown;
};

export function getHover(): Promise<Hover | null | undefined> {
  return neoAiProcess.request<Hover>({ Hover: {} });
}
export async function sendHoverAction(
  id: string,
  selected: string,
  actions: MessageAction[],
  notification_type: unknown,
  state: unknown
): Promise<unknown> {
  return neoAiProcess.request({
    HoverAction: { id, actions, notification_type, state, selected },
  });
}
