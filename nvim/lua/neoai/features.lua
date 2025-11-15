local M = {}

-- Feature registry
local features = {}

-- Initialize features
function M.init(feature_config)
    features = vim.tbl_deep_extend("force", {}, feature_config or {})
    
    -- Log enabled features
    local enabled_features = {}
    for feature, enabled in pairs(features) do
        if enabled then
            table.insert(enabled_features, feature)
        end
    end
    
    if #enabled_features > 0 then
        vim.notify("NeoAI: Enabled features: " .. table.concat(enabled_features, ", "), vim.log.levels.DEBUG)
    end
end

-- Check if feature is enabled
function M.is_enabled(feature)
    return features[feature] == true
end

-- Enable feature
function M.enable(feature)
    features[feature] = true
    vim.notify("NeoAI: Feature enabled: " .. feature, vim.log.levels.DEBUG)
end

-- Disable feature
function M.disable(feature)
    features[feature] = false
    vim.notify("NeoAI: Feature disabled: " .. feature, vim.log.levels.DEBUG)
end

-- Get all features
function M.get_all()
    return vim.deepcopy(features)
end

-- Toggle feature
function M.toggle(feature)
    features[feature] = not features[feature]
    local status = features[feature] and "enabled" or "disabled"
    vim.notify("NeoAI: Feature " .. feature .. " " .. status, vim.log.levels.INFO)
end

-- List enabled features
function M.list_enabled()
    local enabled = {}
    for feature, is_enabled in pairs(features) do
        if is_enabled then
            table.insert(enabled, feature)
        end
    end
    return enabled
end

return M