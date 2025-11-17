local auto_commands = require("neoai.chat.auto_commands")
local chat = require("neoai.chat")
local config = require("neoai.config")
local features = require("neoai.features")
local user_commands = require("neoai.chat.user_commands")

local M = {}

function M.setup()
	features.if_feature_enabled({ "alpha", "plugin.feature.neoai_chat" }, function()
		user_commands.setup()
		auto_commands.setup()
		chat.setup()
	end)

	if config.is_enterprise() then
		user_commands.setup()
		auto_commands.setup()
		chat.setup()
	end
end

return M