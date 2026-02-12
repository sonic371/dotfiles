vim.opt.clipboard = "unnamedplus"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Plugin specs (clean, minimal, focused)
local plugins = {
  -- Core functionality
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "echasnovski/mini.icons", lazy = true },
  
  -- Markdown preview
  { "OXY2DEV/markview.nvim", 
    lazy = false,
    config = function()
      require("markview").setup({
        preview = { icon_provider = "mini" }
      })
    end
  },
  
  -- File explorer
  { 
    "nvim-tree/nvim-tree.lua",
    dependencies = { "echasnovski/mini.icons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
      { "<leader>f", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in tree" },
    },
    config = function() require("nvim-tree").setup() end,
  },
  
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Find in file" },
    },
    config = function()
      require("telescope").setup({
        defaults = { layout_strategy = "horizontal", layout_config = { preview_width = 0.5 } }
      })
    end,
  },
}

-- Initialize lazy
require("lazy").setup({
  spec = plugins,
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
})
