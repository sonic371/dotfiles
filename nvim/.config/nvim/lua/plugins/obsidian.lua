return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "/home/wade/MEGASync/Obsidian/Wade",
      },
    },
    -- Completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      nvim_cmp = false,
      min_chars = 2,
    },
    -- Configure key mappings.
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action depending on context, either follow link or toggle checkbox.
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },

    -- Where to put new notes.
    new_notes_location = "current_dir",

    -- Customize how note IDs are generated.
    note_id_func = function(title)
      -- Create note IDs from the title if it exists, otherwise use a timestamp.
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return suffix
    end,

    -- Preferred link style.
    preferred_link_style = "wiki",

    -- Open URLs in the default web browser (Linux).
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url })
    end,

    -- Picker configuration (using Telescope).
    picker = {
      name = "telescope.nvim",
      note_mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
    },

    -- Sort search results.
    sort_by = "modified",
    sort_reversed = true,

    -- UI settings (disabled because we are using render-markdown.nvim).
    ui = {
      enable = false,
    },
  },
}
