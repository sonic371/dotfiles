return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "echasnovski/mini.icons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
    { "<leader>f", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in tree" },
  },
  config = function()
    require("nvim-tree").setup()
  end,
}