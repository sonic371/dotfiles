vim.opt.clipboard = "unnamedplus"

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Better netrw experience
vim.g.netrw_banner = 0          -- Hide the banner
vim.g.netrw_liststyle = 3        -- Tree style listing
vim.g.netrw_browse_split = 0     -- Open files in previous window
vim.g.netrw_winsize = 75         -- Set initial width
vim.g.netrw_altv = 1             -- Split to the right
vim.g.netrw_preview = 1          -- Preview in a vertical split
vim.g.netrw_keepdir = 0          -- Keep current directory as you navigate
vim.opt.relativenumber = true  -- Enable relative line numbers
vim.opt.number = true          -- Show absolute line number on current line
vim.opt.conceallevel = 2       -- Hide formatting characters for a cleaner look (required for obsidian.nvim)
