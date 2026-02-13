return {
  "brianhuster/live-preview.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    -- LivePreview: close current preview and pick new file
    { "<leader>lp", function()
        vim.cmd("LivePreview close")
        -- Save current buffer if modified before picking new file
        if vim.bo.modified then
          vim.cmd("write")
        end
        vim.cmd("LivePreview pick")
      end,
      desc = "LivePreview: Close & Pick new file"
    },
    -- Close preview
    { "<leader>lc", "<cmd>LivePreview close<CR>", desc = "LivePreview: Close" },
  },
  config = function()
    require('livepreview.config').set({
      -- Server settings (from documentation)
      port = 8081, -- Changed to avoid conflict with port 8080
      browser = "default", -- Use default browser
      dynamic_root = false, -- Use current directory, not parent of current file
      sync_scroll = true, -- Sync scrolling between Neovim and browser
      picker = "telescope", -- Use telescope for file picking
      address = "127.0.0.1", -- Localhost
    })
  end
}
