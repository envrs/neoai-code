local uv = vim.uv or vim.loop
local fn = vim.fn
local json = vim.json
local consts = require("neoai.consts")
local semver = require("neoai.third_party.semver.semver")
local utils = require("neoai.utils")
local NeoaiBinary = {}
local config = require("neoai.config")
local platform = require("neoai.platform")

local api_version = "4.4.223"
local binaries_path = utils.module_dir() .. "/binaries"

local function arch_and_platform()
	local platform_info = platform.get_platform_info()
	if platform_info.os == "linux" and platform_info.arch == "x64" then
		return "x86_64-unknown-linux-musl"
	elseif platform_info.os == "linux" and platform_info.arch == "arm64" then
		return "aarch64-unknown-linux-musl"
	elseif platform_info.os == "mac" and platform_info.arch == "arm64" then
		return "aarch64-apple-darwin"
	elseif platform_info.os == "mac" then
		return "x86_64-apple-darwin"
	elseif platform_info.os == "windows" and platform_info.arch == "x64" then
		return "x86_64-pc-windows-gnu"
	elseif platform_info.os == "windows" then
		return "i686-pc-windows-gnu"
	end
end

local function binary_name()
	if platform.is_windows() then
		return "NeoAi.exe"
	else
		return "NeoAi"
	end
end

local function binary_path()
	local paths = vim.tbl_map(function(path)
		return fn.fnamemodify(path, ":t")
	end, fn.glob(binaries_path .. "/*", true, true))

	paths = vim.tbl_map(function(path)
		return semver(path)
	end, paths)

	table.sort(paths)

	return binaries_path .. "/" .. tostring(paths[#paths]) .. "/" .. arch_and_platform() .. "/" .. binary_name()
end

local function optional_args()
	local config = config.get_config()
	local args = {}
	if config.log_file_path then table.insert(args, "--log-file-path=" .. config.log_file_path) end
	if config.neoai_enterprise_host then table.insert(args, "--cloud2_url=" .. config.neoai_enterprise_host) end
	return args
end

-- Find binary in system PATH
local function find_binary(binary_name)
	local path = vim.fn.exepath(binary_name)
	return path ~= "" and path or nil
end

function NeoaiBinary:start()
	local config = config.get_config()
	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()
	self.handle, self.pid = uv.spawn(binary_path(), {
		args = vim.list_extend({
			"--client",
			"nvim",
			"--client-metadata",
			"ide-restart-counter=" .. self.restart_counter,
			"pluginVersion=" .. consts.plugin_version,
			"--tls_config",
			"insecure=" .. tostring(config.ignore_certificate_errors),
		}, optional_args()),
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function()
		self.handle, self.pid = nil, nil
		uv.read_stop(self.stdout)
	end)

	utils.read_lines_start(
		self.stdout,
		vim.schedule_wrap(function(line)
			local callback = table.remove(self.callbacks)
			if not callback.cancelled then
				local decoded = vim.json.decode(line, { luanil = { object = true, array = true } })
				callback.callback(decoded)
			end
		end),
		vim.schedule_wrap(function(error)
			print("neoai binary read_start error", error)
		end)
	)
end

function NeoaiBinary:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.stdin = nil
	self.stdout = nil
	self.stderr = nil
	self.restart_counter = 0
	self.handle = nil
	self.pid = nil
	self.callbacks = {}

	return o
end

function NeoaiBinary:request(request, on_response)
	if not self.pid then
		self.restart_counter = self.restart_counter + 1
		self:start()
	end
	uv.write(self.stdin, json.encode({ request = request, version = api_version }) .. "\n")
	local callback = { cancelled = false, callback = on_response }
	local function cancel()
		callback.cancelled = true
	end

	table.insert(self.callbacks, 1, callback)
	return cancel
end

-- Expose find_binary function
NeoaiBinary.find_binary = find_binary

-- Helper functions for health checks
function M.get_required_binaries()
	return { "neoai-chat", "neoai-complete" }
end

function M.is_available(binary_name)
	if not binary_name then
		binary_name = "neoai-chat"
	end
	local path = find_binary(binary_name)
	return path ~= nil
end

function M.get_version(binary_name)
	if not binary_name then
		binary_name = "neoai-chat"
	end
	local path = find_binary(binary_name)
	if not path then
		return nil
	end
	
	local result = vim.fn.system(path .. " --version 2>/dev/null"):gsub("%s+", "")
	if vim.v.shell_error == 0 and result ~= "" then
		return result
	end
	
	return "unknown"
end

return NeoaiBinary:new()