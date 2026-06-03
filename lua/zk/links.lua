-- lua/zk/links.lua
-- Follow [[wikilinks]] and markdown links under cursor

local M = {}
local index = require("zk.index")

--- Get wikilink or markdown link target under cursor
---@return string?
local function link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col  = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Check [[wikilink]] or [[wikilink|alias]]
  for link_start, target, alias_or_end, link_end in
  line:gmatch("()%[%[([^%]|]+)([|%]]?)()[%]]?") do
    _ = alias_or_end -- suppress unused
    if col >= link_start and col <= link_end then
      return vim.trim(target)
    end
  end

  -- Also try full pattern for [[wikilink|alias]]
  for s, target, e in line:gmatch("()%[%[([^%]]+)%]%]()") do
    if col >= s and col <= e then
      -- strip alias
      return vim.trim(target:match("^([^|]+)") or target)
    end
  end

  -- Check [text](path) markdown link
  for s, _, path, e in line:gmatch("()%[(.-)%]%(([^)]+)%)()") do
    if col >= s and col <= e then
      path = path:match("^(.-)%.md$") or path
      return vim.fn.fnamemodify(path, ":t:r")
    end
  end

  return nil
end

--- Follow link under cursor, optionally create note if not found
function M.follow_link()
  local ref = link_under_cursor()
  if not ref then
    -- No link found — fall back to default <CR>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    return
  end

  local note = index.resolve(ref)
  if note then
    vim.cmd("edit " .. vim.fn.fnameescape(note.path))
  else
    vim.ui.select({ "Create note", "Cancel" }, {
      prompt = string.format("'%s' not found. ", ref),
    }, function(choice)
      if choice == "Create note" then
        require("zk.notes").new_note(ref)
      end
    end)
  end
end

--- Highlight [[wikilinks]] in current buffer
function M.highlight(buf)
  buf = buf or 0
  -- Use standard namespace
  local ns = vim.api.nvim_create_namespace("zk_links")
  -- Link highlight group
  vim.api.nvim_set_hl(0, "ZkWikiLink", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "ZkBrokenLink", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "ZkLinkBracket", { link = "Comment", default = true })

  -- Treesitter is preferred but we do regex fallback
  -- Clear old marks
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for row, line in ipairs(lines) do
    for s, target, e in line:gmatch("()%[%[([^%]]+)%]%]()") do
      local ref = target:match("^([^|]+)") or target
      ref = vim.trim(ref)
      local hl = index.resolve(ref) and "ZkWikiLink" or "ZkBrokenLink"
      -- brackets
      vim.api.nvim_buf_add_highlight(buf, ns, "ZkLinkBracket", row - 1, s - 1, s + 1)
      vim.api.nvim_buf_add_highlight(buf, ns, hl, row - 1, s + 1, e - 3)
      vim.api.nvim_buf_add_highlight(buf, ns, "ZkLinkBracket", row - 1, e - 3, e - 1)
    end
  end
end

return M
