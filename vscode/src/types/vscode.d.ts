// VSCode API type declarations for the extension
// These will be available at runtime in the VSCode extension host

declare module 'vscode' {
    export type Thenable<T> = PromiseLike<T>;

    export interface ExtensionContext {
        subscriptions: Disposable[];
        workspaceState: Memento;
        globalState: Memento;
        extensionUri: Uri;
        extensionPath: string;
        storagePath?: string;
        globalStoragePath: string;
        logPath: string;
        extensionMode: ExtensionMode;
        environmentVariableCollection: EnvironmentVariableCollection;
        secrets: SecretStorage;
    }

    export interface Memento {
        get<T>(key: string): T | undefined;
        get<T>(key: string, defaultValue: T): T;
        update(key: string, value: any): Thenable<void>;
        keys(): readonly string[];
    }

    export interface EnvironmentVariableCollection {
        get(key: string): string | undefined;
        replace(key: string, value: string | undefined): void;
        append(key: string, value: string): void;
        prepend(key: string, value: string): void;
        clear(): void;
        forEach(callback: (key: string, value: string, collection: EnvironmentVariableCollection) => any, thisArg?: any): void;
        get size(): number;
    }

    export interface SecretStorage {
        get(key: string): Promise<string | undefined>;
        store(key: string, value: string): Promise<void>;
        delete(key: string): Promise<void>;
        onDidChange: Event<SecretStorageChangeEvent>;
    }

    export interface SecretStorageChangeEvent {
        key: string;
    }

    export interface Disposable {
        dispose(): any;
    }

    export interface Event<T> {
        (listener: (e: T) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
    }

    export interface EventEmitter<T> {
        event: Event<T>;
        fire(data?: T): void;
        dispose(): void;
    }

    export interface CancellationToken {
        isCancellationRequested: boolean;
        onCancellationRequested: Event<any>;
    }

    export interface Position {
        line: number;
        character: number;
        isBefore(other: Position): boolean;
        isBeforeOrEqual(other: Position): boolean;
        isAfter(other: Position): boolean;
        isAfterOrEqual(other: Position): boolean;
        isEqual(other: Position): boolean;
        compareTo(other: Position): number;
        translate(lineDelta?: number, characterDelta?: number): Position;
        with(line?: number, character?: number): Position;
    }

    export interface Range {
        start: Position;
        end: Position;
        isEmpty: boolean;
        isSingleLine: boolean;
        contains(positionOrRange: Position | Range): boolean;
        with(start?: Position, end?: Position): Range;
    }

    export interface TextDocument {
        uri: Uri;
        fileName: string;
        isUntitled: boolean;
        languageId: string;
        version: number;
        isDirty: boolean;
        isClosed: boolean;
        save(): Thenable<boolean>;
        getText(range?: Range): string;
        getWordRangeAtPosition(position: Position, regex?: RegExp): Range | undefined;
        getLineCount(): number;
        lineAt(line: number): TextLine;
        offsetAt(position: Position): number;
        positionAt(offset: number): Position;
    }

    export interface TextLine {
        lineNumber: number;
        text: string;
        range: Range;
        firstNonWhitespaceCharacterIndex: number;
        rangeIncludingLineBreak: Range;
        isEmptyOrWhitespace: boolean;
    }

    export interface TextEditor {
        document: TextDocument;
        selection: Selection;
        selections: readonly Selection[];
        visibleRanges: readonly Range[];
        options: TextEditorOptions;
        viewColumn: ViewColumn | undefined;
        edit(callback: (editBuilder: TextEditorEdit) => void, options?: { undoStopBefore: boolean; undoStopAfter: boolean }): Thenable<boolean>;
        insertSnippet(snippet: SnippetString, location?: Position | Range | readonly (Position | Range)[]): Thenable<boolean>;
        setDecorations(decorationType: TextEditorDecorationType, rangesOrOptions: Range[] | DecorationOptions[]): void;
        revealRange(range: Range, revealType?: TextEditorRevealType): void;
        show(position: Position, options?: TextEditorShowOptions): void;
        hide(): void;
    }

    export interface Selection extends Range {
        anchor: Position;
        active: Position;
        isReversed: boolean;
    }

    export interface TextEditorOptions {
        tabSize?: number;
        insertSpaces?: boolean;
        cursorStyle?: TextEditorCursorStyle;
        lineNumbers?: TextEditorLineNumbersStyle;
    }

    export interface TextEditorDecorationType {
        key: string;
        dispose(): void;
    }

    export interface DecorationOptions {
        range: Range;
        hoverMessage?: MarkdownString | string;
        renderOptions?: DecorationRenderOptions;
    }

    export interface DecorationRenderOptions {
        backgroundColor?: string | ThemeColor;
        color?: string | ThemeColor;
        border?: string | ThemeColor;
        borderRadius?: string;
        borderSpacing?: string;
        fontStyle?: string;
        fontWeight?: string;
        textDecoration?: string;
        cursor?: string;
        gutterIconPath?: string | Uri;
        gutterIconSize?: string;
        overviewRulerColor?: string | ThemeColor;
        overviewRulerLane?: OverviewRulerLane;
        before?: ThemableDecorationAttachmentRenderOptions;
        after?: ThemableDecorationAttachmentRenderOptions;
        light?: ThemableDecorationRenderOptions;
        dark?: ThemableDecorationRenderOptions;
        opacity?: number;
    }

    export interface ThemeColor {
        id: string;
    }

    export interface SnippetString {
        value: string;
    }

    export interface MarkdownString {
        value: string;
        isTrusted?: boolean;
        supportThemeIcons?: boolean;
        supportHtml?: boolean;
        baseUri?: Uri;
    }

    export interface Uri {
        scheme: string;
        authority: string;
        path: string;
        query: string;
        fragment: string;
        fsPath: string;
        with(change: { scheme?: string; authority?: string; path?: string; query?: string; fragment?: string }): Uri;
        toString(skipEncoding?: boolean): string;
        toJSON(): any;
    }

    export interface WorkspaceConfiguration {
        get<T>(section: string): T | undefined;
        get<T>(section: string, defaultValue: T): T;
        has(section: string): boolean;
        inspect(section: string): ConfigurationInspect<T> | undefined;
        update(section: string, value: any, configurationTarget?: boolean | ConfigurationTarget): Thenable<void>;
    }

    export interface ConfigurationInspect<T> {
        key: string;
        defaultValue?: T;
        globalValue?: T;
        workspaceValue?: T;
        workspaceFolderValue?: T;
        defaultLanguageValue?: T;
        globalLanguageValue?: T;
        workspaceLanguageValue?: T;
        workspaceFolderLanguageValue?: T;
        languageIds?: string[];
    }

    export interface CompletionItem {
        label: string | CompletionItemLabel;
        kind?: CompletionItemKind;
        tags?: readonly CompletionItemTag[];
        detail?: string;
        documentation?: string | MarkdownString;
        sortText?: string;
        filterText?: string;
        insertText?: string | SnippetString;
        range?: Range | InsertReplaceRange;
        commitCharacters?: readonly string[];
        keepWhitespace?: boolean;
        additionalTextEdits?: TextEdit[];
        command?: Command;
        preselect?: boolean;
    }

    export interface CompletionItemLabel {
        name: string;
        detail?: string;
        qualifiedName?: string;
    }

    export interface InlineCompletionItem {
        insertText: string | SnippetString;
        filterText?: string;
        range?: Range;
        command?: Command;
    }

    export interface CompletionItemProvider<T extends CompletionItem = CompletionItem> {
        provideCompletionItems(
            document: TextDocument,
            position: Position,
            token: CancellationToken,
            context: CompletionContext
        ): ProviderResult<T[] | CompletionList<T>>;
        resolveCompletionItem?(item: T, token: CancellationToken): ProviderResult<T>;
    }

    export interface InlineCompletionItemProvider {
        provideInlineCompletionItems(
            document: TextDocument,
            position: Position,
            context: InlineCompletionContext,
            token: CancellationToken
        ): ProviderResult<InlineCompletionItem[] | InlineCompletionList>;
    }

    export interface CompletionContext {
        triggerKind: CompletionTriggerKind;
        triggerCharacter?: string;
    }

    export interface InlineCompletionContext {
        triggerKind: InlineCompletionTriggerKind;
        selectedCompletionInfo?: SelectedCompletionInfo;
    }

    export interface SelectedCompletionInfo {
        range: Range;
        text: string;
    }

    export interface CompletionList<T extends CompletionItem = CompletionItem> {
        isIncomplete?: boolean;
        items: T[];
    }

    export interface InlineCompletionList {
        items: InlineCompletionItem[];
    }

    export interface TextEdit {
        range: Range;
        newText: string;
    }

    export interface Command {
        title: string;
        command?: string;
        tooltip?: string;
        arguments?: any[];
    }

    export interface TextEditorEdit {
        replace(location: Range | Selection, value: string): void;
        insert(location: Position, value: string): void;
        delete(location: Range | Selection): void;
        setEndOfLine(endOfLine: EndOfLine): void;
    }

    export enum ExtensionMode {
        Production = 1,
        Development = 2,
        Test = 3
    }

    export enum ViewColumn {
        One = 1,
        Two = 2,
        Three = 3,
        Active = -1
    }

    export enum TextEditorCursorStyle {
        Line = 1,
        Block = 2,
        Underline = 3,
        LineThin = 4,
        BlockOutline = 5,
        UnderlineThin = 6
    }

    export enum TextEditorLineNumbersStyle {
        Off = 0,
        On = 1,
        Relative = 2
    }

    export enum TextEditorRevealType {
        Default = 0,
        InCenterIfOutsideViewport = 1,
        InCenter = 2,
        AtTop = 3
    }

    export enum OverviewRulerLane {
        Left = 1,
        Center = 2,
        Right = 4,
        Full = 7
    }

    export enum CompletionItemKind {
        Text = 0,
        Method = 1,
        Function = 2,
        Constructor = 3,
        Field = 4,
        Variable = 5,
        Class = 6,
        Interface = 7,
        Module = 8,
        Property = 9,
        Unit = 10,
        Value = 11,
        Enum = 12,
        Keyword = 13,
        Snippet = 14,
        Color = 15,
        File = 16,
        Reference = 17,
        Folder = 18,
        EnumMember = 19,
        Constant = 20,
        Struct = 21,
        Event = 22,
        Operator = 23,
        TypeParameter = 24
    }

    export enum CompletionItemTag {
        Deprecated = 1
    }

    export enum CompletionTriggerKind {
        Invoke = 0,
        TriggerCharacter = 1,
        TriggerForIncompleteCompletions = 2
    }

    export enum InlineCompletionTriggerKind {
        Automatic = 0,
        Invoke = 1
    }

    export enum EndOfLine {
        LF = 1,
        CRLF = 2
    }

    export enum ConfigurationTarget {
        Global = 1,
        Workspace = 2,
        WorkspaceFolder = 3
    }

    export interface InsertReplaceRange {
        inserting: Range;
        replacing: Range;
    }

    export interface ThemableDecorationAttachmentRenderOptions {
        color?: string | ThemeColor;
        backgroundColor?: string | ThemeColor;
        border?: string | ThemeColor;
        fontStyle?: string;
        fontWeight?: string;
        textDecoration?: string;
        margin?: string;
        width?: string;
        height?: string;
        contentText?: string;
        contentIconPath?: string | Uri;
    }

    export interface ThemableDecorationRenderOptions extends DecorationRenderOptions {
        before?: ThemableDecorationAttachmentRenderOptions;
        after?: ThemableDecorationAttachmentRenderOptions;
    }

    export interface TextEditorShowOptions {
        preserveFocus?: boolean;
    }

    export type ProviderResult<T> = T | undefined | null | Thenable<T | undefined | null>;

    // VSCode API functions
    export function registerCompletionItemProvider<T extends CompletionItem = CompletionItem>(
        selector: DocumentSelector,
        provider: CompletionItemProvider<T>,
        ...triggerCharacters: string[]
    ): Disposable;

    export function registerInlineCompletionItemProvider(
        selector: DocumentSelector,
        provider: InlineCompletionItemProvider
    ): Disposable;

    export function getConfiguration(section?: string): WorkspaceConfiguration;

    // Languages namespace
    export namespace languages {
        export function registerCompletionItemProvider<T extends CompletionItem = CompletionItem>(
            selector: DocumentSelector,
            provider: CompletionItemProvider<T>,
            ...triggerCharacters: string[]
        ): Disposable;

        export function registerInlineCompletionItemProvider(
            selector: DocumentSelector,
            provider: InlineCompletionItemProvider
        ): Disposable;
    }

    // Commands namespace
    export namespace commands {
        export function registerCommand(command: string, callback: (...args: any[]) => any, thisArg?: any): Disposable;
        export function executeCommand<T = any>(command: string, ...rest: any[]): Thenable<T>;
        export function getCommands(filterInternal?: boolean): Thenable<string[]>;
    }

    // Workspace namespace
    export namespace workspace {
        export function getConfiguration(section?: string): WorkspaceConfiguration;
        export function onDidChangeTextDocument(listener: (e: TextDocumentChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function onDidChangeConfiguration(listener: (e: ConfigurationChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function openTextDocument(uri: Uri | string): Thenable<TextDocument>;
        export function asRelativePath(pathOrUri: string | Uri): string;
        export function findFiles(include: string, exclude?: string, maxResults?: number, token?: CancellationToken): Thenable<Uri[]>;
        export function workspaceFolders?: readonly WorkspaceFolder[];
        export function name: string;
        export function rootPath?: string;
    }

    // Window namespace
    export namespace window {
        export const activeTextEditor: TextEditor | undefined;
        export const visibleTextEditors: readonly TextEditor[];
        export function showInformationMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function showWarningMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function showErrorMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function onDidChangeActiveTextEditor(listener: (e: TextEditor | undefined) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function onDidChangeTextEditorSelection(listener: (e: TextEditorSelectionChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function showTextDocument(document: TextDocument, column?: ViewColumn, preserveFocus?: boolean): Thenable<TextEditor>;
    }

    // Uri constructor with file method
    export interface UriStatic {
        (uri: string): Uri;
        file(path: string): Uri;
        parse(path: string): Uri;
        scheme: string;
        with(components: { scheme?: string; authority?: string; path?: string; query?: string; fragment?: string }): Uri;
    }

    export const Uri: UriStatic;

    export interface DocumentSelector {
        language?: string;
        scheme?: string;
        pattern?: string;
    }

    export namespace window {
        export const activeTextEditor: TextEditor | undefined;
        export const visibleTextEditors: readonly TextEditor[];
        export function showInformationMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function showWarningMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function showErrorMessage(message: string, ...items: string[]): Thenable<string | undefined>;
        export function onDidChangeActiveTextEditor(listener: (e: TextEditor | undefined) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function onDidChangeTextEditorSelection(listener: (e: TextEditorSelectionChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
    }

    export interface TextEditorSelectionChangeEvent {
        textEditor: TextEditor;
        selections: readonly Selection[];
        kind?: TextEditorSelectionChangeKind;
    }

    export enum TextEditorSelectionChangeKind {
        Keyboard = 1,
        Mouse = 2,
        Command = 3
    }

    export namespace workspace {
        export function onDidChangeTextDocument(listener: (e: TextDocumentChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
        export function onDidChangeConfiguration(listener: (e: ConfigurationChangeEvent) => any, thisArgs?: any, disposables?: Disposable[]): Disposable;
    }

    export interface TextDocumentChangeEvent {
        document: TextDocument;
        contentChanges: readonly TextDocumentContentChangeEvent[];
    }

    export interface TextDocumentContentChangeEvent {
        range: Range;
        rangeLength: number;
        text: string;
        rangeOffset: number;
    }

    export interface ConfigurationChangeEvent {
        affectsConfiguration(section: string, scope?: ConfigurationScope): boolean;
    }

    export type ConfigurationScope = Uri | TextDocument | WorkspaceFolder | undefined;

    export interface WorkspaceFolder {
        uri: Uri;
        name: string;
        index: number;
    }

    // Constructor functions
    export function EventEmitter<T>(): EventEmitter<T>;
    export function Position(line: number, character: number): Position;
    export function Range(start: Position, end: Position): Range;
    export function Selection(anchor: Position, active: Position): Selection;
    export function CompletionItem(label: string | CompletionItemLabel, kind?: CompletionItemKind): CompletionItem;
    export function InlineCompletionItem(insertText: string | SnippetString, range?: Range): InlineCompletionItem;
    export function MarkdownString(value?: string): MarkdownString;
    export function SnippetString(value?: string): SnippetString;
    export function Uri(uri: string): Uri;
    export function TextEdit(range: Range, newText: string): TextEdit;
}

// Global exports
declare const exports: any;
declare const module: any;
declare const require: any;
declare const process: any;
declare const console: any;
declare const setTimeout: any;
declare const clearTimeout: any;
declare const setInterval: any;
declare const clearInterval: any;
declare const Buffer: any;
declare const __dirname: string;
declare const __filename: string;
