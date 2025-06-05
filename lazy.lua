-- This file demonstrates how to configure this plugin with lazy.nvim
-- Copy this configuration to your lazy.nvim setup

return {
  "ryangreenup/markdown_editor.nvim",
  config = function()
    require("markdown_editor").setup({
      greeting = "Hello from MarkdownEditor!",
      enabled = true,
    })
  end,
  -- Optional: specify when to load the plugin
  -- event = "VeryLazy",
  -- cmd = { "MarkdownEditorGreet", "MarkdownEditorToggle" },
  -- keys = {
  --   { "<leader>mg", "<cmd>MarkdownEditorGreet<cr>", desc = "MarkdownEditor Greet" },
  --   { "<leader>mt", "<cmd>MarkdownEditorToggle<cr>", desc = "MarkdownEditor Toggle" },
  -- },
}
