// Global constants and utilities for NeoAI VSCode extension

export const EXTENSION_NAME = 'neoai';
export const EXTENSION_VERSION = '1.0.0';

export const COMMANDS = {
  ASSISTANT_COMPLETE: 'neoai.assistant.complete',
  ASSISTANT_DIAGNOSE: 'neoai.assistant.diagnose',
  ASSISTANT_QUICK_FIX: 'neoai.assistant.quickFix',
  ASSISTANT_REFACTOR: 'neoai.assistant.refactor',
  ASSISTANT_EXPLAIN: 'neoai.assistant.explain',
  CLEAR_CACHE: 'neoai.cache.clear',
  SET_IGNORE: 'neoai.ignore.set'
} as const;

export const CONFIG_KEYS = {
  ENABLED: 'neoai.enabled',
  API_KEY: 'neoai.apiKey',
  MODEL: 'neoai.model',
  MAX_TOKENS: 'neoai.maxTokens',
  TEMPERATURE: 'neoai.temperature',
  AUTO_DIAGNOSTICS: 'neoai.autoDiagnostics',
  INLINE_COMPLETIONS: 'neoai.inlineCompletions'
} as const;

export const DEFAULT_CONFIG = {
  [CONFIG_KEYS.ENABLED]: true,
  [CONFIG_KEYS.MODEL]: 'gpt-4',
  [CONFIG_KEYS.MAX_TOKENS]: 2048,
  [CONFIG_KEYS.TEMPERATURE]: 0.7,
  [CONFIG_KEYS.AUTO_DIAGNOSTICS]: true,
  [CONFIG_KEYS.INLINE_COMPLETIONS]: true
} as const;

export const SUPPORTED_LANGUAGES = [
  'typescript',
  'javascript', 
  'python',
  'java',
  'cpp',
  'c',
  'csharp',
  'php',
  'ruby',
  'go',
  'rust',
  'swift',
  'kotlin'
] as const;

export const SUPPORTED_FILE_EXTENSIONS = [
  '.ts',
  '.tsx',
  '.js',
  '.jsx',
  '.py',
  '.java',
  '.cpp',
  '.c',
  '.cs',
  '.php',
  '.rb',
  '.go',
  '.rs',
  '.swift',
  '.kt'
] as const;
