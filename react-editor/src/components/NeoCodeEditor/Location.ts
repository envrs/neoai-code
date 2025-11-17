export interface Location {
  readonly uri: string;
  readonly range: {
    readonly start: {
      readonly line: number;
      readonly character: number;
    };
    readonly end: {
      readonly line: number;
      readonly character: number;
    };
  };
}
