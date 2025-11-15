export interface LanguageConfig {
  name: string;
  extensions: string[];
  aliases: string[];
  features: {
    completion: boolean;
    diagnostics: boolean;
    hover: boolean;
    formatting: boolean;
  };
}

export const SUPPORTED_LANGUAGES: Record<string, LanguageConfig> = {
  typescript: {
    name: 'TypeScript',
    extensions: ['.ts', '.tsx'],
    aliases: ['ts', 'tsx'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: true
    }
  },
  javascript: {
    name: 'JavaScript',
    extensions: ['.js', '.jsx'],
    aliases: ['js', 'jsx'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: true
    }
  },
  python: {
    name: 'Python',
    extensions: ['.py'],
    aliases: ['py'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: true
    }
  },
  java: {
    name: 'Java',
    extensions: ['.java'],
    aliases: ['java'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: false
    }
  },
  cpp: {
    name: 'C++',
    extensions: ['.cpp', '.cc', '.cxx'],
    aliases: ['cpp', 'cc', 'cxx'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: false
    }
  },
  c: {
    name: 'C',
    extensions: ['.c'],
    aliases: ['c'],
    features: {
      completion: true,
      diagnostics: true,
      hover: true,
      formatting: false
    }
  }
};

export function getLanguageConfig(languageId: string): LanguageConfig | undefined {
  return SUPPORTED_LANGUAGES[languageId];
}

export function isLanguageSupported(languageId: string): boolean {
  return languageId in SUPPORTED_LANGUAGES;
}

export function getSupportedExtensions(): string[] {
  const extensions: string[] = [];
  Object.values(SUPPORTED_LANGUAGES).forEach(config => {
    extensions.push(...config.extensions);
  });
  return [...new Set(extensions)];
}
