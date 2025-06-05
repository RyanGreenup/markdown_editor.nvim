---@class MyPluginInternalConfig
local M = {}

---@type MyPluginConfig
M.options = {}

---Initialize the configuration
---@param opts MyPluginConfig
function M.setup(opts)
  M.options = opts
end

---Get a configuration value
---@param key string
---@return any
function M.get(key)
  return M.options[key]
end

return M