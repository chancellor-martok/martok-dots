vim.g.mapleader = "<Space>"

require("config.lazy")


local keyset = vim.keymap.set

-- Telescope
local builtin = require('telescope.builtin')
keyset('n', '<C-f>', builtin.find_files, { desc = 'Telescope find files' })
keyset('n', '<C-g>', builtin.live_grep, { desc = 'Telescope live grep' })
keyset('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
keyset('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- cntl-H to open tree
keyset("n", "<C-t>", ":NvimTreeToggle<cr>", { silent = true, noremap = true })

-- cntl-B to open blame
keyset("n", "<C-b>", ":BlameToggle<cr>", { silent = true, noremap = true })

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.number = true

-- Disable textwidth globally
vim.opt.textwidth = 0

-- Create a stronger autocmd that runs after filetype detection
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "FileType"}, {
  group = vim.api.nvim_create_augroup("DisableTextWidth", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.textwidth = 0
    -- Also disable formatoptions that might be causing automatic wrapping
    vim.opt_local.formatoptions = vim.opt_local.formatoptions - "t" - "c" - "a"
  end,
  desc = "Ensure textwidth is always disabled"
})

local macros = vim.api.nvim_exec(
[[
let @b = '<<<<V:s/=/: /^MV:s^<80>kb/^ <80>kb/"/^MV:s/:/":/^Mb'
]], false)

vim.opt.wrap = false

-- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
-- delays and poor user experience
vim.opt.updatetime = 300

-- Always show the signcolumn, otherwise it would shift the text each time
-- diagnostics appeared/became resolved
vim.opt.signcolumn = "yes"

-- Enable copilot
vim.lsp.enable('copilot')

-- Autocomplete
function _G.check_back_space()
  local col = vim.fn.col('.') - 1
  return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Autocomplete tab select
local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)

-- Make <CR> to accept selected completion item or notify coc.nvim to format
-- <C-g>u breaks current undo, please make your own choice
keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

