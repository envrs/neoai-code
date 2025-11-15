local M = {}

-- Register all user commands
function M.register_commands()
    M._register_chat_commands()
    M._register_binary_commands()
    M._register_context_commands()
    M._register_history_commands()
    M._register_utility_commands()
end

-- Register chat interface commands
function M._register_chat_commands()
    -- Open chat interface
    vim.api.nvim_create_user_command("NeoaiChat", function(opts)
        local chat = require("neoai.chat")
        
        if opts.bang then
            -- Force open new chat
            chat.close()
            vim.defer_fn(function()
                chat.open()
            end, 100)
        else
            chat.open()
        end
    end, {
        bang = true,
        desc = "NeoAI: Open chat interface",
    })
    
    -- Close chat interface
    vim.api.nvim_create_user_command("NeoaiChatClose", function()
        local chat = require("neoai.chat")
        chat.close()
    end, {
        desc = "NeoAI: Close chat interface",
    })
    
    -- Toggle chat interface
    vim.api.nvim_create_user_command("NeoaiChatToggle", function()
        local chat = require("neoai.chat")
        if chat.is_active() then
            chat.close()
        else
            chat.open()
        end
    end, {
        desc = "NeoAI: Toggle chat interface",
    })
    
    -- Send message to chat
    vim.api.nvim_create_user_command("NeoaiChatSend", function(opts)
        local chat = require("neoai.chat")
        local message = opts.args
        
        if message == "" then
            -- Send current line or selection
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" or mode == "\22" then
                -- Send visual selection
                chat.send_selection()
            else
                -- Send current line
                chat.send_current_line()
            end
        else
            -- Send provided message
            chat.send_message(message)
        end
    end, {
        nargs = "?",
        desc = "NeoAI: Send message to chat",
    })
    
    -- Quick chat with predefined prompts
    vim.api.nvim_create_user_command("NeoaiChatQuick", function(opts)
        local chat = require("neoai.chat")
        local prompt_type = opts.args
        
        local prompts = {
            explain = "Explain this code",
            refactor = "Refactor this code",
            optimize = "Optimize this code",
            test = "Generate tests for this code",
            debug = "Help me debug this code",
            comment = "Add comments to this code",
        }
        
        local prompt = prompts[prompt_type]
        if not prompt then
            vim.notify("NeoAI: Available quick prompts: " .. table.concat(vim.tbl_keys(prompts), ", "), vim.log.levels.ERROR)
            return
        end
        
        chat.open()
        vim.defer_fn(function()
            -- Get current line or selection
            local mode = vim.fn.mode()
            local code = ""
            
            if mode == "v" or mode == "V" or mode == "\22" then
                -- Get visual selection
                local start_pos = vim.fn.getpos("'<")
                local end_pos = vim.fn.getpos("'>")
                local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
                code = table.concat(lines, "\n")
            else
                -- Get current line
                code = vim.api.nvim_get_current_line()
            end
            
            local full_prompt = string.format("%s:\n\n```%s\n%s\n```", 
                prompt, vim.api.nvim_buf_get_option(0, "filetype"), code)
            chat.send_message(full_prompt)
        end, 500)
    end, {
        nargs = 1,
        complete = function()
            return {"explain", "refactor", "optimize", "test", "debug", "comment"}
        end,
        desc = "NeoAI: Quick chat with predefined prompts",
    })
end

-- Register chat binary commands
function M._register_binary_commands()
    -- Chat binary management
    vim.api.nvim_create_user_command("NeoaiChatBinary", function(opts)
        local chat_binary = require("neoai.chat.binary")
        local action = opts.args
        
        if action == "start" then
            local success, port = chat_binary.start()
            if success then
                vim.notify("NeoAI: Chat binary started on port " .. (port or "unknown"), vim.log.levels.INFO)
            else
                local error_msg = chat_binary.get_last_error() or "Failed to start chat binary"
                vim.notify("NeoAI: " .. error_msg, vim.log.levels.ERROR)
            end
        elseif action == "stop" then
            chat_binary.stop()
            vim.notify("NeoAI: Chat binary stopped", vim.log.levels.INFO)
        elseif action == "restart" then
            chat_binary.restart()
            vim.notify("NeoAI: Chat binary restarting...", vim.log.levels.INFO)
        elseif action == "status" then
            M._show_binary_status()
        elseif action == "check" then
            M._check_binary_availability()
        elseif action == "install" then
            M._show_install_instructions()
        else
            vim.notify("NeoAI: Usage: :NeoaiChatBinary [start|stop|restart|status|check|install]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "?",
        complete = function()
            return {"start", "stop", "restart", "status", "check", "install"}
        end,
        desc = "NeoAI: Manage chat binary",
    })
end

-- Register context commands
function M._register_context_commands()
    -- Context management
    vim.api.nvim_create_user_command("NeoaiChatContext", function(opts)
        local chat = require("neoai.chat")
        local action = opts.args
        
        if action == "add" then
            chat.add_context()
        elseif action == "add_file" then
            chat.add_file_context()
        elseif action == "add_buffer" then
            chat.add_buffer_context()
        elseif action == "add_workspace" then
            chat.add_workspace_context()
        elseif action == "clear" then
            chat.clear_context()
        elseif action == "show" then
            chat.show_context()
        elseif action == "list" then
            chat.list_context()
        else
            vim.notify("NeoAI: Usage: :NeoaiChatContext [add|add_file|add_buffer|add_workspace|clear|show|list]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "?",
        complete = function()
            return {"add", "add_file", "add_buffer", "add_workspace", "clear", "show", "list"}
        end,
        desc = "NeoAI: Manage chat context",
    })
end

-- Register history commands
function M._register_history_commands()
    -- History management
    vim.api.nvim_create_user_command("NeoaiChatHistory", function(opts)
        local chat = require("neoai.chat")
        local action = opts.args
        
        if action == "load" then
            chat.load_history()
        elseif action == "save" then
            chat.save_history()
        elseif action == "clear" then
            chat.clear_history()
        elseif action == "show" then
            chat.show_history()
        elseif action == "export" then
            chat.export_history()
        elseif action == "import" then
            chat.import_history()
        else
            vim.notify("NeoAI: Usage: :NeoaiChatHistory [load|save|clear|show|export|import]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "?",
        complete = function()
            return {"load", "save", "clear", "show", "export", "import"}
        end,
        desc = "NeoAI: Manage chat history",
    })
end

-- Register utility commands
function M._register_utility_commands()
    -- Apply changes
    vim.api.nvim_create_user_command("NeoaiChatApply", function(opts)
        local apply = require("neoai.chat.apply")
        local action = opts.args
        
        if action == "buffer" then
            -- Apply changes to current buffer
            vim.notify("NeoAI: Applying changes to buffer...", vim.log.levels.INFO)
            -- Implementation would depend on having changes stored
        elseif action == "file" then
            -- Apply changes to file
            local file_path = opts.args:gsub("^file%s*", "")
            if file_path == "" then
                file_path = vim.fn.expand("%:p")
            end
            vim.notify("NeoAI: Applying changes to " .. file_path, vim.log.levels.INFO)
            -- Implementation would depend on having changes stored
        else
            vim.notify("NeoAI: Usage: :NeoaiChatApply [buffer|file [path]]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "*",
        desc = "NeoAI: Apply chat suggestions",
    })
    
    -- Configuration
    vim.api.nvim_create_user_command("NeoaiChatConfig", function(opts)
        local action = opts.args
        
        if action == "show" then
            M._show_config()
        elseif action == "reset" then
            M._reset_config()
        elseif action == "setup" then
            M._run_setup()
        else
            vim.notify("NeoAI: Usage: :NeoaiChatConfig [show|reset|setup]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "?",
        complete = function()
            return {"show", "reset", "setup"}
        end,
        desc = "NeoAI: Chat configuration",
    })
    
    -- Debug commands
    vim.api.nvim_create_user_command("NeoaiChatDebug", function(opts)
        local action = opts.args
        
        if action == "info" then
            M._show_debug_info()
        elseif action == "logs" then
            M._show_logs()
        elseif action == "test" then
            M._run_tests()
        else
            vim.notify("NeoAI: Usage: :NeoaiChatDebug [info|logs|test]", vim.log.levels.ERROR)
        end
    end, {
        nargs = "?",
        complete = function()
            return {"info", "logs", "test"}
        end,
        desc = "NeoAI: Chat debugging",
    })
end

-- Helper functions
function M._show_binary_status()
    local chat_binary = require("neoai.chat.binary")
    local status = chat_binary.get_state()
    
    local lines = {
        "NeoAI Chat Binary Status",
        "========================",
        "",
        "Running: " .. (status.running and "✓ Yes" or "✗ No"),
    }
    
    if status.running then
        table.insert(lines, "Port: " .. (status.port or "Unknown"))
        table.insert(lines, "Process ID: " .. (status.process_id or "Unknown"))
    end
    
    if status.last_error then
        table.insert(lines, "")
        table.insert(lines, "Last Error: " .. status.last_error)
    end
    
    local content = table.concat(lines, "\n")
    vim.notify(content, vim.log.levels.INFO)
end

function M._check_binary_availability()
    local chat = require("neoai.chat")
    local available = chat.check_binary_availability()
    
    if available then
        vim.notify("NeoAI: Chat binary is available", vim.log.levels.INFO)
    else
        vim.notify("NeoAI: Chat binary is not available", vim.log.levels.WARN)
    end
end

function M._show_install_instructions()
    local binary = require("neoai.chat.binary")
    local instructions = binary.get_install_instructions()
    
    -- Create buffer to show instructions
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "neoai-install")
    vim.api.nvim_buf_set_option(buf, "filetype", "text")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(instructions, "\n"))
    
    -- Open in a new window
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        col = math.floor(vim.o.columns * 0.1),
        row = math.floor(vim.o.lines * 0.1),
        border = "rounded",
    })
end

function M._show_config()
    local setup = require("neoai.chat.setup")
    local config = setup.get_config()
    
    local lines = {"NeoAI Chat Configuration", "========================", ""}
    M._add_config_to_lines(lines, config, 0)
    
    local content = table.concat(lines, "\n")
    vim.notify(content, vim.log.levels.INFO)
end

function M._add_config_to_lines(lines, config, indent)
    local indent_str = string.rep("  ", indent)
    
    for key, value in pairs(config) do
        if type(value) == "table" then
            table.insert(lines, indent_str .. key .. ":")
            M._add_config_to_lines(lines, value, indent + 1)
        else
            table.insert(lines, indent_str .. key .. ": " .. tostring(value))
        end
    end
end

function M._reset_config()
    local setup = require("neoai.chat.setup")
    setup.setup({})
    vim.notify("NeoAI: Chat configuration reset to defaults", vim.log.levels.INFO)
end

function M._run_setup()
    local setup = require("neoai.chat.setup")
    setup.setup({})
    vim.notify("NeoAI: Chat setup completed", vim.log.levels.INFO)
end

function M._show_debug_info()
    local chat_binary = require("neoai.chat.binary")
    local chat = require("neoai.chat")
    local state = require("neoai.state")
    
    local lines = {
        "NeoAI Chat Debug Info",
        "=====================",
        "",
        "Chat Active: " .. (chat.is_active() and "Yes" or "No"),
        "Binary Running: " .. (chat_binary.is_running() and "Yes" or "No"),
        "Binary Port: " .. (chat_binary.get_port() or "N/A"),
        "Last Error: " .. (chat_binary.get_last_error() or "None"),
        "",
        "State:",
        "  Connected: " .. tostring(state.get("connected")),
        "  API Key Valid: " .. tostring(state.get("api_key_valid")),
        "  Chat Active: " .. tostring(state.get("chat_active")),
        "  Last Error: " .. tostring(state.get("last_error")),
    }
    
    local content = table.concat(lines, "\n")
    vim.notify(content, vim.log.levels.INFO)
end

function M._show_logs()
    local log_file = vim.fn.stdpath("data") .. "/neoai/chat.log"
    
    if vim.fn.filereadable(log_file) == 1 then
        vim.cmd("edit " .. log_file)
    else
        vim.notify("NeoAI: No log file found at " .. log_file, vim.log.levels.WARN)
    end
end

function M._run_tests()
    vim.notify("NeoAI: Running chat tests...", vim.log.levels.INFO)
    
    -- Run basic tests
    local tests = {
        function()
            local chat_binary = require("neoai.chat.binary")
            local available, info = chat_binary.check_availability()
            return available, "Chat binary available"
        end,
        function()
            local chat = require("neoai.chat")
            local active = chat.is_active()
            return true, "Chat status check: " .. (active and "active" or "inactive")
        end,
        function()
            local state = require("neoai.state")
            local healthy = state.is_healthy()
            return healthy, "State healthy: " .. tostring(healthy)
        end,
    }
    
    local passed = 0
    local failed = 0
    
    for i, test in ipairs(tests) do
        local success, message = pcall(test)
        if success then
            local result, msg = message
            if result then
                passed = passed + 1
                vim.notify("✓ Test " .. i .. ": " .. msg, vim.log.levels.INFO)
            else
                failed = failed + 1
                vim.notify("✗ Test " .. i .. ": " .. msg, vim.log.levels.ERROR)
            end
        else
            failed = failed + 1
            vim.notify("✗ Test " .. i .. ": " .. message, vim.log.levels.ERROR)
        end
    end
    
    vim.notify(string.format("NeoAI: Tests completed - %d passed, %d failed", passed, failed), 
        failed > 0 and vim.log.levels.ERROR or vim.log.levels.INFO)
end

return M
