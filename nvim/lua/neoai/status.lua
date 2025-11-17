local uv = vim.uv or vim.loop
local fn = vim.fn
local utils = require("neoai.utils")

local M = {}
local DISABLED_FILE = utils.module_dir() .. "/.disabled"
local config = require("neoai.config")
local state = require("neoai.state")
local neoai_binary = require("neoai.binary")
local service_level = nil
local status_prefix = "⌬ neoai"

local function poll_service_level()
	local timer = uv.new_timer()
	timer:start(
		0,
		5000,
		vim.schedule_wrap(function()
			neoai_binary:request({ State = { dummy_property = true } }, function(response)
				if response and (response.service_level == "Pro" or response.service_level == "Trial") then
					service_level = "pro"
				elseif response and response.service_level == "Business" then
					service_level = "enterprise"
				elseif response and response.service_level == "Dev" then
					service_level = "dev"
				else
					service_level = "basic"
				end
			end)
		end)
	)
end

function M.setup()
	if config.is_enterprise() then
		service_level = "enterprise"
	else
		poll_service_level()
	end
	local _, disabled_file_exists = pcall(fn.filereadable, DISABLED_FILE)
	state.active = disabled_file_exists == 0
end

function M.enable_neoai()
	pcall(fn.delete, DISABLED_FILE)
	state.active = true
end

function M.disable_neoai()
	pcall(fn.writefile, { "" }, DISABLED_FILE, "b")
	state.active = false
end

function M.toggle_neoai()
	if state.active then
		M.disable_neoai()
	else
		M.enable_neoai()
	end
end

function M.status()
	if state.active == false then return status_prefix .. " disabled" end

	if not service_level then return status_prefix .. " loading" end

	return status_prefix .. " " .. service_level
end

return M