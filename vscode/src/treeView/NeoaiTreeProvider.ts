/* eslint-disable class-methods-use-this */
import { Event, ProviderResult, TreeDataProvider, TreeItem } from "vscode";
import {
  NEOAI_OPEN_APP_COMMAND,
  NEOAI_OPEN_GETTING_STARTED_COMMAND,
  NEOAI_TREE_NAVIGATION_COMMAND,
} from "../globals/consts";
import NeoaiTreeItem from "./NeoaiTreeItem";

export default class NeoaiTreeProvider
  implements TreeDataProvider<NeoaiTreeItem> {
  onDidChangeTreeData?:
    | Event<void | NeoaiTreeItem | null | undefined>
    | undefined;

  getTreeItem(element: NeoaiTreeItem): TreeItem {
    return element as TreeItem;
  }

  getChildren(): ProviderResult<NeoaiTreeItem[]> {
    return [
      new NeoaiTreeItem("Manage your team", {
        title: "Manage your team",
        command: NEOAI_OPEN_APP_COMMAND,
        arguments: [],
      }),
      new NeoaiTreeItem("Configure your IDE", {
        title: "Configure your IDE",
        command: NEOAI_TREE_NAVIGATION_COMMAND,
        arguments: [],
      }),
      new NeoaiTreeItem("Getting Started guide", {
        title: "Getting Started guide",
        command: NEOAI_OPEN_GETTING_STARTED_COMMAND,
        arguments: [],
      }),
    ];
  }
}
