export class CancellationToken {
  private _isCancellationRequested: boolean = false;
  private readonly abortController = new AbortController();

  public get isCancellationRequested(): boolean {
    return this._isCancellationRequested;
  }

  public get signal(): AbortSignal {
    return this.abortController.signal;
  }

  public cancel(): void {
    if (!this._isCancellationRequested) {
      this._isCancellationRequested = true;
      this.abortController.abort();
    }
  }
}
