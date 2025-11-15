# NeoAI Assistant IntelliJ Plugin

AI-powered code completion and assistance for IntelliJ IDEA.

## Features

- **AI Code Completions**: Intelligent inline code suggestions powered by NeoAI
- **Code Generation**: Generate code with AI prompts (Ctrl+Shift+G)
- **Code Explanation**: Explain selected code with AI (Ctrl+Shift+E)
- **Smart Context Awareness**: Understands your code context for better suggestions
- **Multiple Language Support**: Works with Java, Kotlin, Python, JavaScript, and more
- **Customizable Settings**: Configure API, models, and behavior

## Installation

1. Build the plugin: `./gradlew buildPlugin`
2. Install the built plugin from `build/distributions/`
3. Configure your NeoAI API token in Settings > Tools > NeoAI Assistant

## Configuration

### Required Settings
- **API Token**: Your NeoAI API token
- **API URL**: NeoAI API endpoint (default: https://api.neoai.com)

### Optional Settings
- **Model**: AI model to use (default: neoai-coder)
- **Max Tokens**: Maximum tokens for completion (default: 1000)
- **Temperature**: Response randomness (default: 0.1)
- **Debounce**: Delay before requesting completions (default: 500ms)

### Disable Patterns
You can disable completions for specific files or lines using regex patterns:
- **File Patterns**: Disable completions for certain file paths
- **Line Patterns**: Disable completions for lines matching patterns

## Usage

### Code Completions
- Completions appear automatically as you type
- Press Tab to accept a completion
- Completions are context-aware and language-specific

### Code Generation
1. Select text or place cursor where you want code
2. Press `Ctrl+Shift+G` or use Code > Generate Code with AI
3. Enter your prompt
4. Review and insert the generated code

### Code Explanation
1. Select code you want to understand
2. Press `Ctrl+Shift+E` or use Code > Explain Code with AI
3. View the AI-generated explanation

### Intentions
- Right-click on code and look for NeoAI intentions
- "Generate code with AI" appears in the intention menu

## Development

### Building
```bash
./gradlew build
./gradlew buildPlugin
```

### Running
```bash
./gradlew runIde
```

### Testing
```bash
./gradlew test
```

## Requirements

- IntelliJ IDEA 2023.2 or later
- Java 17 or later
- Valid NeoAI API token

## License

This plugin is part of the NeoAI project.
