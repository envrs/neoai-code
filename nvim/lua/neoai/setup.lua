local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local status = require("neoai.status")
local workspace = require("neoai.workspace")
local features = require("neoai.features")
local user_commands = require("neoai.user_commands")
local keymaps = require("neoai.keymaps")
local auto_commands = require("neoai.auto_commands")
 lsp = require("neoai.lsp")
local completion = require("neoai.completion")
local binary = require("neoai.binary")

local M = {}

-- Main setup function
function M.setup(user_config)
    -- Validate Neovim version
    if not M.check_neovim_version() then
        return
    end
    
    -- Initialize state
    state.init()
    
    -- Setup configuration
    config.setup(user_config)
    
    -- Initialize workspace
    workspace.init()
    
    -- Setup features
    features.setup()
    
    -- Setup LSP integration
    lsp.setup()
    
    -- Initialize completion
    completion.init()
    
    -- Setup user commands
    user_commands.setup()
    
    -- Setup keymaps
    keymaps.setup()
    
    -- Setup autocommands
    auto_commands.setup()
    
    -- Register status updates
    status.register_updates()
    
    -- Check binary dependencies
    M.check_dependencies()
    
    vim.notify("NeoAI: Plugin setup complete", vim.log.levels.INFO)
end

-- Check Neovim version
function M.check_neovim_version()
    local version = vim.version()
    local required_version = consts.MIN_NVIM_VERSION
    
    if version.major < required_version.major or 
       (version.major == required_version.major and version.minor < required_version.minor) then
        vim.notify(string.format(
            "NeoAI requires Neovim >= %d.%d, but you have %d.%d",
            required_version.major, required_version.minor,
            version.major, version.minor
        ), vim.log.levels.ERROR)
        return false
    end
    
    return true
end

-- Check binary dependencies
function M.check_dependencies()
    local required_binaries = {"curl", "git"}
    local optional_binaries = {"node", "python3", "rg", "fd"}
    
    local missing_required = {}
    local available_optional = {}
    
    -- Check required binaries
    for _, binary in ipairs(required_binaries) do
        if not binary.is_available(binary) then
            table.insert(missing_required, binary)
        end
    end
    
    -- Check optional binaries
    for _, binary in ipairs(optional_binaries) do
        if binary.is_available(binary) then
            table.insert(available_optional, binary)
        end
    end
    
    -- Report missing required binaries
    if #missing_required > 0 then
        vim.notify(
            "NeoAI: Missing required binaries: " .. table.concat(missing_required, ", "),
            vim.log.levels.ERROR
        )
    end
    
    -- Report available optional binaries
    if #available_optional > 0 then
        vim.notify(
            "NeoAI: Optional binaries available: " .. table.concat(available_optional, ", "),
            vim.log.levels.DEBUG
        )
    end
end

-- Health check
function M.health_check()
    local health = {
        ok = 0,
        warn = 0,
        error = 0,
        checks = {},
    }
    
    -- Check Neovim version
    if M.check_neovim_version() then
        health.ok = health.ok + 1
        table.insert(health.checks, {
            name = "Neovim version",
            status = "ok",
            message = "Compatible version",
        })
    else
        health.error = health.error + 1
        table.insert(health.checks, {
            name = "Neovim version",
            status = "error",
            message = "Incompatible version",
        })
    end
    
    -- Check configuration
    local current_config = config.get()
    if current_config.api_key then
        health.ok = health.ok + 1
        table.insert(health.checks, {
            name = "API key",
            status = "ok",
            message = "Configured",
        })
    else
        health.warn = health.warn + 1
        table.insert(health.checks, {
            name = "API key",
            status = "warn",
            message = "Not configured",
        })
    end
    
    -- Check workspace
    local workspace_root = state.get("workspace_root")
    if workspace_root and vim.fn.isdirectory(workspace_root) == 1 then
        health.ok = health.ok + 1
        table.insert(health.checks, {
            name = "Workspace",
            status = "ok",
            message = workspace_root,
        })
    else
        health.error = health.error + 1
        table.insert(health.checks, {
            name = "Workspace",
            status = "error",
            message = "Invalid workspace",
        })
    end
    
    -- Check features
    local enabled_features = features.list_enabled()
    if #enabled_features > 0 then
        health.ok = health.ok + 1
        table.insert(health.checks, {
            name = "Features",
            status = "ok",
            message = table.concat(enabled_features, ", "),
        })
    else
        health.warn = health.warn + 1
        table.insert(health.checks, {
            name = "Features",
            status = "warn",
            message = "No features enabled",
        })
    end
    
    -- Check binary dependencies
    local required_binaries = {"curl", "git"}
    local missing_binaries = {}
    
    for _, binary in ipairs(required_binaries) do
        if not binary.is_available(binary) then
            table.insert(missing_binaries, binary)
        end
    end
    
    if #missing_binaries == 0 then
        health.ok = health.ok + 1
        table.insert(health.checks, {
            name = "Dependencies",
            status = "ok",
            message = "All required binaries available",
        })
    else
        health.warn = health.warn + 1
        table.insert(health.checks, {
            name = "Dependencies",
            status = "warn",
            message = "Missing: " .. table.concat(missing_binaries, ", "),
        })
    end
    
    -- Display health report
    M.display_health_report(health)
    
    return health
end

-- Display health report
function M.display_health_report(health)
    local lines = {
        "NeoAI Health Check",
        "==================",
        "",
        string.format("Summary: %d OK, %d WARN, %d ERROR", health.ok, health.warn, health.error),
        "",
    }
    
    for _, check in ipairs(health.checks) do
        local status_symbol = "✓"
        if check.status == "warn" then
            status_symbol = "⚠"
        elseif check.status == "error" then
            status_symbol = "✗"
        end
        
        table.insert(lines, string.format("%s %s: %s", status_symbol, check.name, check.message))
    end
    
    local message = table.concat(lines, "\n")
    local level = vim.log.levels.INFO
    
    if health.error > 0 then
        level = vim.log.levels.ERROR
    elseif health.warn > 0 then
        level = vim.log.levels.WARN
    end
    
    vim.notify(message, level)
end

-- Reload plugin
function M.reload()
    -- Clear existing state
    state.reset()
    
    -- Clear binary cache
    binary.clear_cache()
    
    -- Re-setup
    M.setup(config.get())
    
    vim.notify("NeoAI: Plugin reloaded", vim.log.levels.INFO)
end

-- Get plugin information
function M.get_info()
    return {
        name = "neoai",
        version = "1.0.0",
        description = "AI-powered coding assistant for Neovim",
        author = "NeoAI Team",
        homepage = "https://github.com/neoai/neoai.nvim",
        dependencies = {"curl", "git"},
        optional_dependencies = {"node", "python3", "rg", "fd"},
        min_neovim_version = consts.MIN_NVIM_VERSION,
        features = features.get_all(),
        commands = user_commands.get_commands(),
        keymaps = keymaps.get_keymaps(),
    }
end

-- Cleanup plugin
function M.cleanup()
    -- Close chat if active
    if state.get("chat_active") then
        local chat = require("neoai.chat")
        chat.close()
    end
    
    -- Stop completion if active
    if state.get("completion_active") then
        completion.stop()
    end
    
    -- Clear state
    state.reset()
    
    -- Clear autocommands
    auto_commands.cleanup()
    
    vim.notify("NeoAI: Plugin cleanup complete", vim.log.levels.DEBUG)
end

return M
