-- Common Neovim key mappings
-- 
-- Follows Vim conventions with modern improvements

local function setup_keymaps()
  -- ========== NAVIGATION ==========
  -- Buffer navigation
  vim.keymap.set("n", "<C-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
  vim.keymap.set("n", "<C-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
  vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
  vim.keymap.set("n", "<leader>bl", "<cmd>buffers<CR>", { desc = "List buffers" })

  -- Window navigation (using Ctrl + hjkl)
  vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
  vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
  vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
  vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

  -- Tab navigation
  vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
  vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
  vim.keymap.set("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
  vim.keymap.set("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })

  -- ========== FILE OPERATIONS ==========
  -- Save
  vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

  -- Quit
  vim.keymap.set("n", "<leader>q", "<cmd>q!<CR>", { desc = "Quit" })
  vim.keymap.set("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Force quit" })

  -- Yank to system clipboard
  vim.keymap.set("n", "<leader>Y", '%y', { desc = "Yank all to clipboard" })
end

return {
  setup = setup_keymaps
}
