import React from 'react';
import Editor, { OnMount } from '@monaco-editor/react';
import { useNeo } from './NeoProvider';
import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';
import { CompletionProvider } from './NeoCodeEditor/CompletionProvider';
import { InlineCompletionProvider } from './NeoCodeEditor/InlineCompletionProvider';
import { DEFAULT_HEIGHT, DEFAULT_THEME } from './NeoCodeEditor/defaultValues';

export interface NeoCodeEditorProps {
  language: string;
  value: string;
  onChange?: (value: string | undefined) => void;
  height?: string;
  theme?: 'vs-dark' | 'light';
}

export const NeoCodeEditor: React.FC<NeoCodeEditorProps> = ({
  language,
  value,
  onChange,
  height = DEFAULT_HEIGHT,
  theme = DEFAULT_THEME,
}) => {
  const { apiClient } = useNeo();

  const handleEditorDidMount: OnMount = (editor, monacoInstance) => {
    const completionProvider = new CompletionProvider(apiClient, language);
    const completionDisposable =
      monacoInstance.languages.registerCompletionItemProvider(
        language,
        completionProvider,
      );

    const inlineCompletionProvider = new InlineCompletionProvider(
      apiClient,
      language,
    );
    const inlineCompletionDisposable =
      monacoInstance.languages.registerInlineCompletionsProvider(
        language,
        inlineCompletionProvider,
      );

    return () => {
      completionDisposable.dispose();
      inlineCompletionDisposable.dispose();
    };
  };

  return (
    <Editor
      height={height}
      language={language}
      value={value}
      onChange={onChange}
      theme={theme}
      onMount={handleEditorDidMount}
    />
  );
};
