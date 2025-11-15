local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local utils = require("neoai.utils")

local M = {}

-- Workspace context
local workspace_context = {
    files = {},
    directories = {},
    last_updated = nil,
}

-- Initialize workspace
function M.init()
    local root = vim.fn.getcwd()
    state.set_workspace_root(root)
    M.update_workspace_files()
end

-- Update workspace files
function M.update_workspace_files()
    local root = state.get("workspace_root") or vim.fn.getcwd()
    local files = M.scan_workspace(root)
    
    workspace_context.files = files
    workspace_context.last_updated = os.time()
    state.update_workspace_files(files)
    
    vim.notify("NeoAI: Workspace updated - " .. #files .. " files", vim.log.levels.DEBUG)
end

-- Scan workspace for files
function M.scan_workspace(root)
    local files = {}
    local exclude_patterns = {
        "%.git", "%.svn", "%.hg", -- Version control
        "node_modules", "__pycache__", "target", "build", "dist", -- Build directories
        "%.cache", "%.tmp", -- Cache directories
    }
    
    -- Use vim.fn.glob to find files
    local all_files = vim.fn.glob(root .. "/**/*", false, true)
    
    for _, file_path in ipairs(all_files) do
        -- Skip directories
        if vim.fn.isdirectory(file_path) == 0 then
            -- Skip excluded files
            local should_include = true
            for _, pattern in ipairs(exclude_patterns) do
                if file_path:match(pattern) then
                    should_include = false
                    break
                end
            end
            
            if should_include then
                local relative_path = file_path:sub(root:len() + 2) -- Remove root and separator
                local file_info = {
                    path = relative_path,
                    full_path = file_path,
                    type = M.get_file_type(file_path),
                    size = vim.fn.getfsize(file_path),
                    modified = vim.fn.getftime(file_path),
                }
                table.insert(files, file_info)
            end
        end
    end
    
    return files
end

-- Get file type
function M.get_file_type(file_path)
    local ext = utils.get_extension(file_path)
    
    if not ext then
        return "unknown"
    end
    
    -- Code files
    local code_exts = {
        "lua", "py", "js", "ts", "jsx", "tsx", "java", "cpp", "c", "h", "hpp",
        "go", "rs", "cs", "php", "rb", "swift", "kt", "scala", "dart", "rust"
    }
    
    -- Config files
    local config_exts = {
        "json", "yaml", "yml", "toml", "ini", "cfg", "conf", "xml", "plist"
    }
    
    -- Documentation files
    local doc_exts = {
        "md", "txt", "rst", "org", "adoc", "tex"
    }
    
    if vim.tbl_contains(code_exts, ext) then
        return "code"
    elseif vim.tbl_contains(config_exts, ext) then
        return "config"
    elseif vim.tbl_contains(doc_exts, ext) then
        return "documentation"
    else
        return "other"
    end
end

-- Get workspace context for AI
function M.get_context(max_files, max_content)
    max_files = max_files or 50
    max_content = max_content or 10000
    
    local root = state.get("workspace_root") or vim.fn.getcwd()
    local current_file = vim.api.nvim_buf_get_name(0)
    local files = workspace_context.files
    
    -- Sort files by relevance (current file first, then recently modified)
    local sorted_files = {}
    for _, file in ipairs(files) do
        file.relevance = 0
        
        -- Current file gets highest relevance
        if file.full_path == current_file then
            file.relevance = file.relevance + 100
        end
        
        -- Same directory as current file
        local current_dir = current_file:match("(.*/)")
        local file_dir = file.full_path:match("(.*/)")
        if current_dir and file_dir and current_dir == file_dir then
            file.relevance = file.relevance + 50
        end
        
        -- Recently modified files
        local time_diff = os.time() - file.modified
        if time_diff < 3600 then -- Last hour
            file.relevance = file.relevance + 20
        elseif time_diff < 86400 then -- Last day
            file.relevance = file.relevance + 10
        end
        
        -- Code files get higher relevance
        if file.type == "code" then
            file.relevance = file.relevance + 5
        end
        
        table.insert(sorted_files, file)
    end
    
    -- Sort by relevance
    table.sort(sorted_files, function(a, b)
        return a.relevance > b.relevance
    end)
    
    -- Take top files
    local context_files = {}
    local total_content = 0
    
    for i, file in ipairs(sorted_files) do
        if i > max_files or total_content > max_content then
            break
        end
        
        local content = utils.read_file(file.full_path)
        if content then
            local file_content = {
                name = file.path,
                type = file.type,
                content = content:sub(1, max_content - total_content), -- Truncate if needed
                size = #content,
            }
            table.insert(context_files, file_content)
            total_content = total_content + #file_content.content
        end
    end
    
    return {
        root = root,
        current_file = current_file,
        files = context_files,
        total_files = #files,
        context_size = total_content,
    }
end

-- Handle file changes
function M.on_file_changed(file_path)
    local root = state.get("workspace_root") or vim.fn.getcwd()
    
    -- Update file in workspace context
    for i, file in ipairs(workspace_context.files) do
        if file.full_path == file_path then
            file.modified = vim.fn.getftime(file_path)
            file.size = vim.fn.getfsize(file_path)
            break
        end
    end
    
    -- Update last modified time
    workspace_context.last_updated = os.time()
end

-- Update context
function M.update_context()
    -- Debounced workspace update
    M.update_workspace_files()
end

-- Find files by pattern
function M.find_files(pattern, file_type)
    local matches = {}
    
    for _, file in ipairs(workspace_context.files) do
        local matches_pattern = not pattern or file.path:match(pattern)
        local matches_type = not file_type or file.type == file_type
        
        if matches_pattern and matches_type then
            table.insert(matches, file)
        end
    end
    
    return matches
end

-- Get file by path
function M.get_file(path)
    local root = state.get("workspace_root") or vim.fn.getcwd()
    local full_path = path:sub(1, 1) == "/" and path or (root .. "/" .. path)
    
    for _, file in ipairs(workspace_context.files) do
        if file.full_path == full_path or file.path == path then
            return file
        end
    end
    
    return nil
end

-- Get workspace statistics
function M.get_statistics()
    local stats = {
        total_files = #workspace_context.files,
        file_types = {},
        total_size = 0,
        last_updated = workspace_context.last_updated,
    }
    
    for _, file in ipairs(workspace_context.files) do
        -- Count file types
        stats.file_types[file.type] = (stats.file_types[file.type] or 0) + 1
        -- Sum sizes
        stats.total_size = stats.total_size + file.size
    end
    
    return stats
end

return M