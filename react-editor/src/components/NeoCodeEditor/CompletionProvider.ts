import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';
import { CancellationToken } from './CancellationToken';
import { CompletionRequest } from '../../proto/language_server_pb';
import { languageIdToEnum } from '../../utils/language';
import { numCodeUnitsToNumUtf8Bytes } from '../../utils/utf';
import { createApiClient } from '../../api/client';

type ApiClient = ReturnType<typeof createApiClient>;

export class CompletionProvider implements monaco.languages.CompletionItemProvider {
  private cancellationToken: CancellationToken | null = null;

  constructor(
    private readonly apiClient: ApiClient,
    private readonly language: string,
  ) {}

  public async provideCompletionItems(
    model: monaco.editor.ITextModel,
    position: monaco.Position,
    context: monaco.languages.CompletionContext,
    token: monaco.CancellationToken,
  ): Promise<monaco.languages.CompletionList> {
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

    const request = new CompletionRequest({
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
      },
      offset: BigInt(utf8Offset),
    });

    try {
      const response = await this.apiClient.completion(request, {
        signal: localCancellationToken.signal,
      });
      if (localCancellationToken.isCancellationRequested) {
        return { suggestions: [] };
      }
      const suggestions: monaco.languages.CompletionItem[] = response.items.map(
        (item: any) => ({
          label: item.label,
          kind: item.kind ?? monaco.languages.CompletionItemKind.Text,
          insertText: item.insertText,
          range: item.range
            ? new monaco.Range(
                item.range.start.line + 1,
                item.range.start.character + 1,
                item.range.end.line + 1,
                item.range.end.character + 1,
              )
            : new monaco.Range(
                position.lineNumber,
                position.column,
                position.lineNumber,
                position.column,
              ),
        }),
      );
      return { suggestions };
    } catch (error) {
      if (!localCancellationToken.isCancellationRequested) {
        console.error('Error getting completions:', error);
      }
      return { suggestions: [] };
    }
  }
}
