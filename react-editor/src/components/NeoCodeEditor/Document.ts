export interface Position {
  /**
   * Line position in a document (zero-based).
   */
  readonly line: number;
  /**
   * Character offset on a line in a document (zero-based).
   */
  readonly character: number;
}

export interface Range {
  /**
   * The range's start position.
   */
  readonly start: Position;
  /**
   * The range's end position.
   */
  readonly end: Position;
}

export interface TextDocument {
  readonly uri: string;
  readonly languageId: string;
  readonly version: number;
  readonly lineCount: number;

  getText(range?: Range): string;
  offsetAt(position: Position): number;
  positionAt(offset: number): Position;
}
