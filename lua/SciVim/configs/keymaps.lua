--[[
-- Keymaps for SciVim
--]]

local map = vim.keymap.set

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map({ "n", "i", "v", "s" }, "<C-s>", "<Cmd>w<CR><esc>", { desc = "Save", noremap = true, silent = true })

map("n", "<C-q>", "<Cmd>q!<CR>", { desc = "Quit", noremap = true, silent = true })
map("n", "<C-c>", "<Cmd>bdelete!<CR>", { desc = "Kill Buffer", noremap = true, silent = true })
--[[
-- Moving
--]]

map("n", "<S-Down>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<S-Up>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<S-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<S-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<S-Down>", "<cmd>m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<S-Up>", "<cmd>m '<-2<cr>gv=gv", { desc = "Move Up" })
--[[
-- Focusing
--]]
map("n", "<C-h>", "<C-w>h", { desc = "Focus Left", noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Focus Down", noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Focus Up", noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Focus Right", noremap = true, silent = true })
--[[
-- Resizing
--]]
map("n", "<C-Up>", "<Cmd> resize +2<CR>", { desc = "Inc Height", noremap = true, silent = true })
map("n", "<C-Down>", "<Cmd> resize -2<CR>", { desc = "Dec Height", noremap = true, silent = true })
map("n", "<C-Left>", "<Cmd> vertical resize +2<CR>", { desc = "Inc Width", noremap = true, silent = true })
map("n", "<C-Right>", "<Cmd> vertical resize -2<CR>", { desc = "Dec Width", noremap = true, silent = true })
--[[
-- N behaviour
--]]

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("n", "<leader>S", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", {
  desc = "Exit Search",
  noremap = true,
  silent = true,
})
-- Normal-mode commands
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keyword help", noremap = true, silent = true })
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

--[[
--indenting
--]]

map("v", "<", "<gv")
map("v", ">", ">gv")

--[[
-- Commenting
--]]
--
map("n", "gcO", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gco", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  ---@diagnostic disable-next-line: deprecated
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", "<cmd>InspectTree<cr>", { desc = "Inspect Tree" })

-- Terminal Mappings
map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

local function get_all_buffer_filetypes()
  local buffer_filetypes = {}
  -- Iterate over all buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    -- Get the filetype of the current buffer
    ---@diagnostic disable-next-line: deprecated
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
    -- Store the filetype in the table
    buffer_filetypes[bufnr] = filetype
  end
  return buffer_filetypes
end





map("n", "<leader>Bf", function()
  local files = get_all_buffer_filetypes()
  for bufnr, filetype in pairs(files) do
    print("Buffer " .. bufnr .. " has ft: " .. filetype)
  end
end, { desc = "Filetype Checker" })


map("x", "<leader>p", [["_dP"]], { desc = "Awesome 1" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Awesome 2" })
map("n", "<leader>Y", [["+Y]], { desc = "Awesome 3" })
