# NeoAI.nvim

An AI-powered coding assistant for Neovim that provides intelligent code completion, chat interface, and workspace integration.

## Features

- **Chat Interface**: Interactive AI chat with context awareness
- **Auto Completion**: AI-powered code completion with multi-language support
- **Workspace Integration**: Understands your project structure and context
- **LSP Integration**: Enhanced with Language Server Protocol support
- **Multi-language Support**: Works with Lua, Python, JavaScript, TypeScript, and more
- **Customizable**: Extensive configuration options and feature toggles

## Requirements

- Neovim >= 0.8.0
- curl (for API requests)
- git (for workspace operations)

Optional dependencies:
- node or python3 (for enhanced features)
- rg (ripgrep) for faster file searching
- fd for faster file discovery

## Installation

### Using packer.nvim

```lua
use {
  "neoai/neoai.nvim",
  config = function()
    require("neoai").setup({
      -- Configuration options
      api_key = "your-api-key-here",
      features = {
        chat_interface = true,
        auto_complete = true,
        workspace_integration = true,
        lsp_integration = true,
      },
    })
  end
}
```

### Using vim-plug

```vim
Plug 'neoai/neoai.nvim'
lua require("neoai").setup({api_key = "your-api-key-here"})
```

## Configuration

### Basic Setup

```lua
require("neoai").setup({
  api_key = "your-api-key-here",
  model = "gpt-3.5-turbo",
  features = {
    chat_interface = true,
    auto_complete = true,
    workspace_integration = true,
    lsp_integration = true,
  },
  completion = {
    trigger_length = 3,
    max_suggestions = 5,
    debounce_ms = 300,
    exclude_filetypes = {
      "gitcommit", "gitrebase", "svn", "hgcommit", "diff", "patch",
      "help", "man", "qf", "startify", "nerdtree", "NvimTree",
      "neo-tree", "alpha", "dashboard", "TelescopePrompt", "WhichKey",
      "lspinfo", "checkhealth", "log", "markdown", "text", "rst",
    },
  },
  chat = {
    max_messages = 50,
    context_lines = 20,
  },
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | string | `nil` | Your AI service API key |
| `model` | string | `"gpt-3.5-turbo"` | AI model to use |
| `features.chat_interface` | boolean | `true` | Enable chat interface |
| `features.auto_complete` | boolean | `true` | Enable auto completion |
| `features.workspace_integration` | boolean | `true` | Enable workspace integration |
| `features.lsp_integration` | boolean | `true` | Enable LSP integration |
| `keymaps.enabled` | boolean | `true` | Enable default keymaps |
| `keymaps.override_conflicts` | boolean | `false` | Override conflicting keymaps |
| `keymaps.show_conflict_warnings` | boolean | `true` | Show conflict warnings |
| `keymaps.custom_keymaps` | table | `{}` | Custom keymap definitions |
| `completion.trigger_length` | number | `3` | Minimum characters to trigger completion |
| `completion.max_suggestions` | number | `5` | Maximum number of suggestions |
| `completion.debounce_ms` | number | `300` | Debounce time for auto-completion |
| `completion.exclude_filetypes` | table | `see below` | File types to exclude from completion |
| `chat.max_messages` | number | `50` | Maximum messages in chat history |
| `chat.context_lines` | number | `20` | Number of context lines for chat |

### Default Excluded File Types

By default, NeoAI excludes completion for the following file types to avoid interference with specialized buffers and improve performance:

**Version Control**: `gitcommit`, `gitrebase`, `svn`, `hgcommit`, `diff`, `patch`
**Documentation**: `help`, `man`, `markdown`, `text`, `rst`
**UI/Plugin Buffers**: `nerdtree`, `NvimTree`, `neo-tree`, `alpha`, `dashboard`, `startify`
**Telescope/WhichKey**: `TelescopePrompt`, `TelescopeResults`, `WhichKey`
**LSP/Diagnostics**: `lspinfo`, `null-ls-info`, `checkhealth`, `health`, `log`, `qf`
**Other**: `git`, `gitconfig`, `fugitive`, `fugitiveblame`, `vim-plug`

You can customize this list by setting your own `exclude_filetypes` array in the configuration.

### Keymap Configuration

NeoAI provides flexible keymap configuration to prevent conflicts with other plugins:

```lua
require("neoai").setup({
  keymaps = {
    enabled = true,                    -- Enable default keymaps
    override_conflicts = false,        -- Don't override existing keymaps
    show_conflict_warnings = true,     -- Show warnings for conflicts
    custom_keymaps = {                 -- Add your own keymaps
      {
        mode = "n",
        lhs = "<leader>ai",
        rhs = function()
          require("neoai.chat").toggle()
        end,
        opts = { desc = "NeoAI Chat", silent = true },
      },
    },
  },
})
```

#### Keymap Conflict Management

NeoAI automatically detects keymap conflicts and provides several options:

- **Default behavior**: Warns about conflicts and skips conflicting keymaps
- **Override mode**: Set `override_conflicts = true` to override existing keymaps
- **Silent mode**: Set `show_conflict_warnings = false` to suppress warnings
- **Disabled mode**: Set `enabled = false` to disable all default keymaps

#### Keymap Commands

Check keymap status:
```vim
:NeoaiKeymaps status
```

Check for conflicts:
```vim
:NeoaiKeymaps check
```

Clear all NeoAI keymaps:
```vim
:NeoaiKeymaps clear
```

Re-setup keymaps:
```vim
:NeoaiKeymaps setup
```

## Usage

### Chat Interface

Open the chat interface:
```vim
:NeoaiChat
```

Or use the keymap:
```vim
<leader>ac
```

Chat commands:
- `<Enter>`: Send message
- `<C-c>`: Clear chat
- `<C-w>`: Close chat
- `<Tab>`: Insert current file
- `<C-r>`: Insert selection

### Auto Completion

Trigger completion manually:
```vim
:NeoaiComplete
```

Or use the keymap in insert mode:
```vim
<C-g>
```

**Note**: NeoAI automatically hides its completion suggestions when the built-in popup menu (pum) is visible, ensuring no interference with native Vim completion or other completion plugins.

### Workspace Integration

Get workspace context:
```lua
local context = require("neoai").get_context({
  max_files = 50,
  max_content = 10000,
})
```

### LSP Integration

View LSP information:
```vim
:NeoaiLspInfo
```

Get document symbols:
```vim
:NeoaiLspSymbols
```

### Status and Configuration

Check plugin status:
```vim
:NeoaiStatus
```

Show configuration:
```vim
:NeoaiConfig show
```

Reset configuration:
```vim
:NeoaiConfig reset
```

Toggle features:
```vim
:NeoaiToggle chat_interface
:NeoaiToggle auto_complete
```

## Keymaps

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>ac` | Normal | Toggle chat interface |
| `<leader>at` | Normal | Toggle feature selection |
| `<leader>as` | Normal | Show status |
| `<leader>acfg` | Normal | Show configuration |
| `<C-g>` | Insert | Trigger completion |

## API

### Core Functions

```lua
-- Setup plugin
require("neoai").setup(config)

-- Get plugin status
local status = require("neoai").status()

-- Get workspace context
local context = require("neoai").get_context(opts)

-- Check if plugin is ready
local ready = require("neoai").is_ready()

-- Check plugin health
local healthy = require("neoai").is_healthy()

-- Reload plugin
require("neoai").reload()
```

### Workspace API

```lua
local workspace = require("neoai.workspace")

-- Initialize workspace
workspace.init()

-- Update workspace files
workspace.update_workspace_files()

-- Get context
local context = workspace.get_context(max_files, max_content)

-- Find files
local files = workspace.find_files(pattern, file_type)

-- Get file info
local file = workspace.get_file(path)

-- Get statistics
local stats = workspace.get_statistics()
```

### LSP API

```lua
local lsp = require("neoai.lsp")

-- Get LSP context
local context = lsp.get_lsp_context(bufnr, max_symbols)

-- Get document symbols
lsp.get_document_symbols(bufnr)

-- Get code actions
local actions = lsp.get_code_actions(bufnr, range)

-- Get hover info
local hover = lsp.get_hover_info(bufnr, position)
```

## Troubleshooting

### Health Check

Run a health check to diagnose issues:
```vim
:lua require("neoai.setup").health_check()
```

### Common Issues

1. **API Key not configured**
   ```
   NeoAI: API key not configured
   ```
   Set your API key in the configuration.

2. **Missing dependencies**
   ```
   NeoAI: Missing required binaries: curl, git
   ```
   Install the required system dependencies.

3. **Workspace not detected**
   ```
   NeoAI: Invalid workspace
   ```
   Make sure you're in a valid directory.

4. **LSP not available**
   ```
   NeoAI: No LSP clients attached
   ```
   Setup LSP for your language.

### Debug Mode

Enable debug logging:
```lua
require("neoai").setup({
  -- ... other config
  debug = true,
})
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License

## Support

- Issues: [GitHub Issues](https://github.com/neoai/neoai.nvim/issues)
- Discussions: [GitHub Discussions](https://github.com/neoai/neoai.nvim/discussions)

## Changelog

### v1.0.0
- Initial release
- Chat interface
- Auto completion
- Workspace integration
- LSP integration
- Multi-language support
