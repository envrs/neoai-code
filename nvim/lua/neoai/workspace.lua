local neoai_binary = require("neoai.binary")
local uv = vim.uv or vim.loop
local lsp = vim.lsp
local config = require("neoai.config")
local utils = require("neoai.utils")

local M = {}

local function workspace_folders()
	local config = config.get_config().workspace_folders
	local result = {}

	if config.lsp and #utils.buf_get_clients() > 0 then
		vim.list_extend(result, utils.set(lsp.buf.list_workspace_folders()))
	end

	if config.paths then vim.list_extend(result, config.paths) end

	if config.get_paths then vim.list_extend(result, config.get_paths() or {}) end

	return result
end

function M.update()
	neoai_binary:request({ Workspace = { root_paths = workspace_folders() } }, function() end)
end

function M.update_context()
	M.update()
end

function M.get_workspace_root()
	-- Try to get workspace root from LSP
	local clients = utils.buf_get_clients()
	for _, client in ipairs(clients) do
	 local folders = client.workspace_folders or {}
	 if #folders > 0 then
		return folders[1].name
	 end
	end
	
	-- Try to get from git
	local git_root = ""
	if vim.fn.executable("git") == 1 then
		git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+", "")
	end
	if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
		return git_root
	end
	
	-- Fallback to current directory
	return vim.fn.getcwd()
end

function M.get_context()
	local root = M.get_workspace_root()
	local files = {}
	local total_size = 0
	
	-- Get all files in workspace (simplified)
	local function scan_dir(dir, max_depth)
		max_depth = max_depth or 3
		if max_depth <= 0 then return end
		
		local entries = vim.fn.readdir(dir)
		for _, entry in ipairs(entries) do
			if entry ~= "." and entry ~= ".." then
				local path = dir .. "/" .. entry
				local attr = vim.fn.getfperm(path)
				if attr:match("r") then
					if vim.fn.isdirectory(path) == 1 then
						-- Skip common ignore directories
						if not entry:match("^%.") and 
						   entry ~= "node_modules" and 
						   entry ~= "target" and 
						   entry ~= "build" and
						   entry ~= "dist" and
						   entry ~= "__pycache__" then
							scan_dir(path, max_depth - 1)
						end
					else
						-- Include source files
						local ext = vim.fn.fnamemodify(entry, ":e"):lower()
						if ext == "lua" or ext == "py" or ext == "js" or ext == "ts" or
						   ext == "java" or ext == "cpp" or ext == "c" or ext == "h" or
						   ext == "rs" or ext == "go" or ext == "php" or ext == "rb" then
							local size = vim.fn.getfsize(path)
							if size > 0 then
								table.insert(files, path)
								total_size = total_size + size
							end
						end
					end
				end
			end
		end
	end
	
	scan_dir(root)
	
	return {
		root = root,
		total_files = #files,
		files = files,
		context_size = total_size,
	}
end

function M.update_workspace_files()
	-- Trigger a workspace update
	M.update()
	
	-- Notify user
	local context = M.get_context()
	vim.notify(string.format("Workspace updated: %d files found", context.total_files), vim.log.levels.INFO)
end

function M.setup()
	local timer = uv.new_timer()

	timer:start(0, 30000, vim.schedule_wrap(M.update))
end

return M