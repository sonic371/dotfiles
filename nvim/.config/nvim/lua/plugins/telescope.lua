return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-media-files.nvim",
    "jvgrootveld/telescope-zoxide",
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
    { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Find in file" },
    { "<leader>fm", "<cmd>Telescope media_files<CR>", desc = "Media files" },
    { "<leader>fz", "<cmd>Telescope zoxide list<CR>", desc = "Zoxide directories" },
  },
  config = function()
    local z_utils = require("telescope._extensions.zoxide.utils")

    require("telescope").setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { preview_width = 0.5 }
      },
      extensions = {
        media_files = {
          -- filetypes whitelist
          filetypes = { "png", "jpg", "jpeg", "mp4", "webm", "pdf", "webp" },
          -- find command (defaults to `fd`)
          find_cmd = "fd"
        },
        zoxide = {
          prompt_title = "[ Zoxide Directories ]",
          mappings = {
            default = {
              action = function(selection)
                vim.cmd.cd(selection.path)
              end,
              after_action = function(selection)
                vim.notify("Directory changed to " .. selection.path)
              end,
            },
            ["<C-s>"] = { action = z_utils.create_basic_command("split") },
            ["<C-v>"] = { action = z_utils.create_basic_command("vsplit") },
            ["<C-e>"] = { action = z_utils.create_basic_command("edit") },
            ["<C-t>"] = {
              action = function(selection)
                vim.cmd.tcd(selection.path)
              end,
            },
          }
        }
      }
    })

    require("telescope").load_extension("media_files")
    require("telescope").load_extension("zoxide")
  end,
}