-- This file demonstrates how to configure this plugin with lazy.nvim
-- Copy this configuration to your lazy.nvim setup

return {
  "your-username/myplugin.nvim",
  config = function()
    require("myplugin").setup({
      greeting = "Hello from MyPlugin!",
      enabled = true,
    })
  end,
  -- Optional: specify when to load the plugin
  -- event = "VeryLazy",
  -- cmd = { "MyPluginGreet", "MyPluginToggle" },
  -- keys = {
  --   { "<leader>mg", "<cmd>MyPluginGreet<cr>", desc = "MyPlugin Greet" },
  --   { "<leader>mt", "<cmd>MyPluginToggle<cr>", desc = "MyPlugin Toggle" },
  -- },
}