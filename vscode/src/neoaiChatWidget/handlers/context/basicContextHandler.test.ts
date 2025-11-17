import * as vscode from "vscode";
import { expect } from "chai";
import * as sinon from "sinon";
import { getPredominantWorkspaceLanguage } from "./basicContextHandler";

describe("getPredominantWorkspaceLanguage", () => {
  afterEach(() => {
    sinon.restore();
  });

  it("should return expected language for given files", async () => {
    const mockFiles = [
      vscode.Uri.parse("/path/to/file1.js"),
      vscode.Uri.parse("/path/to/file2.js"),
    ];
    sinon.stub(vscode.workspace, "findFiles").resolves(mockFiles);
    sinon.stub(vscode.workspace, "getConfiguration").returns({
      get: () => ({}),
    } as any);
    sinon.stub(vscode.workspace, "workspaceFolders").value([{}]);

    const result = await getPredominantWorkspaceLanguage();
    expect(result).to.equal("javascript");
  });

  it("should return undefined when file extensions are not known", async () => {
    const mockFiles = [
      vscode.Uri.parse("/path/to/file1.unknown"),
      vscode.Uri.parse("/path/to/file2.unknown"),
    ];
    sinon.stub(vscode.workspace, "findFiles").resolves(mockFiles);
    sinon.stub(vscode.workspace, "getConfiguration").returns({
      get: () => ({}),
    } as any);
    sinon.stub(vscode.workspace, "workspaceFolders").value([{}]);

    const result = await getPredominantWorkspaceLanguage();
    expect(result).to.equal(undefined);
  });

  it("should return the language which has most files in sample", async () => {
    const mockFiles = [
      vscode.Uri.parse("/path/to/file1.js"),
      vscode.Uri.parse("/path/to/file2.js"),
      vscode.Uri.parse("/path/to/file3.go"),
      vscode.Uri.parse("/path/to/file4.go"),
      vscode.Uri.parse("/path/to/file5.go"),
    ];
    sinon.stub(vscode.workspace, "findFiles").resolves(mockFiles);
    sinon.stub(vscode.workspace, "getConfiguration").returns({
      get: () => ({}),
    } as any);
    sinon.stub(vscode.workspace, "workspaceFolders").value([{}]);

    const result = await getPredominantWorkspaceLanguage();
    expect(result).to.equal("go");
  });

  it("should respect exclude settings", async () => {
    const mockFiles: vscode.Uri[] = [];
    const findFilesStub = sinon
      .stub(vscode.workspace, "findFiles")
      .resolves(mockFiles);
    sinon.stub(vscode.workspace, "getConfiguration").returns({
      get: (key: string) => {
        if (key === "files.exclude") {
          return { "**/*.js": true };
        }
        if (key === "search.exclude") {
          return { "**/*.ts": true };
        }
        return {};
      },
    } as any);
    sinon.stub(vscode.workspace, "workspaceFolders").value([{}]);

    await getPredominantWorkspaceLanguage();
    expect(findFilesStub.getCall(0).args[1]).to.include("**/*.js");
    expect(findFilesStub.getCall(0).args[1]).to.include("**/*.ts");
  });
});