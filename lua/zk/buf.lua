-- lua/zk/buf.lua
-- Per-buffer setup for markdown files inside the vault

local M = {}
local index = require("zk.index")
local links = require("zk.links")

local function cfg() return require("zk").config end

--- Check whether a buffer's file is inside the vault
---@param buf integer
---@return boolean
local function in_vault(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local dir  = cfg().dir
  return path:sub(1, #dir) == dir and path:match("%.md$") ~= nil
end

--- Attach ZK behaviour to a markdown buffer
function M.attach()
  local buf = vim.api.nvim_get_current_buf()
  if not in_vault(buf) then return end
  if vim.b[buf].zk_attached then return end
  vim.b[buf].zk_attached = true

  -- Initial highlight pass
  vim.schedule(function() links.highlight(buf) end)

  -- Re-highlight on text change (debounced)
  local timer = nil
  local au_id = vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function()
      if timer then timer:stop() end
      timer = vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(buf) then
          links.highlight(buf)
        end
      end, 400)
    end,
  })

  -- Update index on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer   = buf,
    callback = function()
      local path = vim.api.nvim_buf_get_name(buf)
      index.update_file(path)
      links.highlight(buf)
    end,
  })

  -- Status line info: note id + tags
  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = buf,
    callback = function()
      local path = vim.api.nvim_buf_get_name(buf)
      local note = index._notes[path]
      if note then
        vim.b[buf].zk_title = note.title
        vim.b[buf].zk_tags  = table.concat(note.tags, " ")
      end
    end,
  })

  -- Cleanup
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer   = buf,
    once     = true,
    callback = function()
      vim.api.nvim_del_autocmd(au_id)
    end,
  })
end

--- Return statusline component string (call from your statusline)
function M.statusline()
  local title = vim.b.zk_title
  if not title then return "" end
  local tags = vim.b.zk_tags
  if tags and tags ~= "" then
    return string.format(" %s [%s]", title, tags)
  end
  return " " .. title
end

return M
