import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';
import { CancellationToken } from './CancellationToken';
import { createApiClient } from '../../api/client';
import { InlineCompletionRequest } from '../../proto/language_server_pb';
import { languageIdToEnum } from '../../utils/language';
import { numCodeUnitsToNumUtf8Bytes } from '../../utils/utf';

type ApiClient = ReturnType<typeof createApiClient>;

export class InlineCompletionProvider
  implements monaco.languages.InlineCompletionsProvider
{
  private cancellationToken: CancellationToken | null = null;

  constructor(
    private readonly apiClient: ApiClient,
    private readonly language: string,
  ) {}

  public async provideInlineCompletions(
    model: monaco.editor.ITextModel,
    position: monaco.Position,
    context: monaco.languages.InlineCompletionContext,
    token: monaco.CancellationToken,
  ): Promise<monaco.languages.InlineCompletions | undefined> {
    if (this.cancellationToken) {
      this.cancellationToken.cancel();
    }
    this.cancellationToken = new CancellationToken();
    const localCancellationToken = this.cancellationToken;

    token.onCancellationRequested(() => {
      localCancellationToken.cancel();
    });

    const text = model.getValue();
    const offset = model.getOffsetAt(position);
    const utf8Offset = numCodeUnitsToNumUtf8Bytes(text, offset);

    const request = new InlineCompletionRequest({
      document: {
        uri: model.uri.toString(),
        content: text,
        languageId: languageIdToEnum(this.language),
        version: model.getVersionId(),
      },
      position: {
        line: position.lineNumber - 1,
        character: position.column - 1,
      },
      context: {
        triggerKind: context.triggerKind,
        selectedCompletionInfo: context.selectedCompletionInfo
          ? {
              range: context.selectedCompletionInfo.range,
              text: context.selectedCompletionInfo.text,
            }
          : undefined,
      },
      offset: BigInt(utf8Offset),
    });

    try {
      const response = await this.apiClient.inlineCompletion(request, {
        signal: localCancellationToken.signal,
      });

      if (localCancellationToken.isCancellationRequested) {
        return { items: [] };
      }

      const items: monaco.languages.InlineCompletion[] = response.items.map(
        (item: any) => ({
          insertText: item.insertText,
          range: item.range
            ? new monaco.Range(
                item.range.start.line + 1,
                item.range.start.character + 1,
                item.range.end.line + 1,
                item.range.end.character + 1,
              )
            : undefined,
        }),
      );

      return { items };
    } catch (error) {
      if (!localCancellationToken.isCancellationRequested) {
        console.error('Error getting inline completions:', error);
      }
      return { items: [] };
    }
  }
}
