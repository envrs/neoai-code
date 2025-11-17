import { Command, TreeItem, TreeItemCollapsibleState } from "vscode";

export default class NeoaiTreeItem extends TreeItem {
  constructor(
    public readonly label: string,
    public readonly command?: Command
  ) {
    super(label, TreeItemCollapsibleState.None);

    this.tooltip = `${this.label}`;
  }

  contextValue = "neoai";
}
