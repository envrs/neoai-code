# NeoAI Examples

This directory contains comprehensive examples demonstrating various aspects of the NeoAI Neovim plugin. Each example focuses on specific features and use cases to help you get the most out of NeoAI.

## 📁 Example Files

### 🚀 Getting Started

- **`basic_setup.lua`** - Minimal configuration to get started quickly
- **`advanced_config.lua`** - Comprehensive configuration with all options
- **`python.py`** - Enhanced Python code example with various patterns

### ⚙️ Configuration & Customization

- **`custom_keymaps.lua`** - Setting up custom keymaps and shortcuts
- **`enterprise_setup.lua`** - Enterprise-specific configuration and security

### 🔧 Feature-Specific Examples

- **`completion_examples.lua`** - Auto-completion scenarios and tuning
- **`chat_automation.lua`** - Chat interface automation and workflows
- **`workspace_integration.lua`** - Workspace context and file management
- **`lsp_integration.lua`** - LSP integration and symbol navigation

### 🌐 Language Support

- **`language_specific.lua`** - Configurations for different programming languages

### 🐛 Troubleshooting

- **`troubleshooting.lua`** - Debugging tools and health checks

## 📖 Usage Guide

### Basic Setup

Start with `basic_setup.lua` for a quick start:

```lua
require("neoai").setup({
  api_key = "your-api-key-here",
  model = "gpt-3.5-turbo",
})
```

### Advanced Configuration

See `advanced_config.lua` for comprehensive options including:
- Feature toggles
- Completion settings
- Custom keymaps
- Enterprise configuration

### Language-Specific Features

The `language_specific.lua` example shows how to:
- Configure settings per programming language
- Create language-specific commands
- Set up custom prompts for different languages

### Chat Automation

`chat_automation.lua` demonstrates:
- Sending code to chat automatically
- Generating documentation
- Code refactoring workflows
- Debugging assistance

### Workspace Integration

`workspace_integration.lua` covers:
- Getting workspace context
- Finding files
- File information
- Workspace statistics

### LSP Integration

`lsp_integration.lua` shows:
- Getting LSP context
- Symbol navigation
- Code actions
- Hover information

## 🎯 Common Workflows

### 1. Code Review Workflow

```vim
:NeoaiReview  " From chat_automation.lua
```

### 2. Documentation Generation

```vim
<leader>cad  " Generate docs for current function (chat_automation.lua)
```

### 3. Debugging Assistance

```vim
<leader>cade  " Debug current code (chat_automation.lua)
```

### 4. Language-Specific Help

```vim
:NeoaiExplain  " Explain current code (language_specific.lua)
:NeoaiDebug    " Debug current code (language_specific.lua)
:NeoaiRefactor " Refactor current code (language_specific.lua)
```

### 5. Health Check

```vim
:NeoaiHealth  " Run comprehensive health check (troubleshooting.lua)
```

## 🔧 Configuration Tips

### Performance Tuning

Adjust completion settings based on your needs:

```lua
completion = {
  trigger_length = 2,        -- Lower for faster triggers
  debounce_ms = 150,         -- Lower for faster responses
  max_suggestions = 3,       -- Reduce for less UI clutter
}
```

### Language-Specific Optimization

Configure per-language settings:

```lua
-- For Python (more context needed)
chat.context_lines = 30

-- For Lua (faster responses)
completion.debounce_ms = 100
```

### Enterprise Security

For enterprise environments:

```lua
-- Disable file logging for security
log_file_path = nil

-- Exclude sensitive file types
completion.exclude_filetypes = {"secrets", "config", "confidential"}
```

## 🚨 Troubleshooting

### Common Issues

1. **API Key Not Found**
   ```vim
   :lua print(require("neoai.config").get("api_key"))
   ```

2. **Binary Not Available**
   ```bash
   cd nvim/chat && cargo build --release
   ```

3. **LSP Not Working**
   ```vim
   :lua require("neoai.troubleshoot").check_lsp()
   ```

### Debug Mode

Enable debug logging:

```lua
require("neoai").setup({
  debug = true,
})
```

Generate debug report:

```vim
:NeoaiDebug
```

## 🎨 Customization Examples

### Custom Keymaps

```lua
-- Custom chat toggle
vim.keymap.set("n", "<leader>ai", function()
  require("neoai.chat").toggle()
end, { desc = "NeoAI Chat" })
```

### Custom Commands

```lua
vim.api.nvim_create_user_command("MyAICommand", function()
  -- Your custom AI command
end, {})
```

### Auto-Commands

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    -- Python-specific setup
  end,
})
```

## 📚 Integration Examples

### With Other Plugins

```lua
-- Integration with telescope
vim.keymap.set("n", "<leader>af", function()
  require("telescope.builtin").find_files({
    prompt_title = "Find files for AI context",
  })
end, { desc = "Find files for AI" })
```

### With Git

```lua
-- Send git diff to chat
vim.keymap.set("n", "<leader>agd", function()
  local diff = vim.fn.system("git diff")
  require("neoai.chat").submit_message("Review this git diff:\n\n" .. diff)
end, { desc = "AI Git Diff" })
```

## 🏢 Enterprise Features

### Security Considerations

- Disable logging for sensitive environments
- Exclude confidential file types
- Use enterprise-specific endpoints

### Team Configuration

```lua
-- Shared team configuration
workspace_folders = {
  paths = { "/projects/team-project", "/work/company-app" },
  lsp = true,
}
```

## 📝 Contributing Examples

To add new examples:

1. Create a new `.lua` file in this directory
2. Add comprehensive comments
3. Include practical use cases
4. Update this README

## 📞 Getting Help

- Check the main NeoAI documentation
- Run `:NeoaiHealth` for diagnostics
- Use `:NeoaiDebug` for detailed information
- Check the troubleshooting example for common issues

---

*These examples are designed to be educational and practical. Feel free to adapt them to your specific workflow and needs!*
