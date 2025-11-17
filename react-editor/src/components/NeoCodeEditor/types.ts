import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';

export type Monaco = typeof monaco;
export type Editor = monaco.editor.IStandaloneCodeEditor;
export type Position = monaco.Position;
export type Range = monaco.Range;
export type CancellationToken = monaco.CancellationToken;
export type ITextModel = monaco.editor.ITextModel;
