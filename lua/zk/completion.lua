-- lua/zk/completion.lua
-- Provides [[ wikilink completion via nvim-cmp, blink.cmp, or native omnifunc

local M = {}
local index = require("zk.index")

-- ─── nvim-cmp source ─────────────────────────────────────────────────────────

local cmp_source = {}
cmp_source.__index = cmp_source

function cmp_source.new()
  return setmetatable({}, cmp_source)
end

function cmp_source:get_trigger_characters()
  return { "[" }
end

function cmp_source:get_keyword_pattern()
  return [[\[\[.*]]
end

function cmp_source:is_available()
  return vim.bo.filetype == "markdown"
end

function cmp_source:complete(params, callback)
  local line = params.context.cursor_before_line
  -- Only trigger when inside [[
  if not line:match("%[%[[^%]]*$") then
    callback({ items = {} })
    return
  end

  local notes = index.all()
  local items = {}
  for _, note in ipairs(notes) do
    items[#items + 1] = {
      label         = note.id,
      filterText    = note.title .. " " .. note.id,
      insertText    = note.id .. "]]",
      kind          = 18, -- Reference
      documentation = {
        kind  = "markdown",
        value = string.format("**%s**\n\n`%s`\n\nTags: %s",
          note.title,
          note.path,
          table.concat(note.tags, ", ")
        ),
      },
      data          = note,
    }
  end

  callback({ items = items, isIncomplete = false })
end

-- ─── blink.cmp source ────────────────────────────────────────────────────────

local blink_source = {}
blink_source.__index = blink_source

function blink_source.new()
  return setmetatable({}, blink_source)
end

function blink_source:get_trigger_characters()
  return { "[" }
end

function blink_source:enabled()
  return vim.bo.filetype == "markdown"
end

function blink_source:get_completions(ctx, callback)
  local line = ctx.line:sub(1, ctx.cursor[2])
  if not line:match("%[%[[^%]]*$") then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local notes = index.all()
  local items = {}
  for _, note in ipairs(notes) do
    items[#items + 1] = {
      label         = note.id,
      filterText    = note.title .. " " .. note.id,
      textEdit      = {
        newText = note.id .. "]]",
        range   = {
          start   = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
          ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
        },
      },
      kind          = 18,
      documentation = string.format("**%s**\n\n%s", note.title, note.path),
    }
  end

  callback({
    items                  = items,
    is_incomplete_forward  = false,
    is_incomplete_backward = false,
  })
end

-- ─── Native omnifunc fallback ─────────────────────────────────────────────────

local function omnifunc(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2]
    local sub  = line:sub(1, col)
    local s    = sub:find("%[%[[^%[]*$")
    return s and (s + 1) or -1
  end

  local notes = index.all()
  local results = {}
  local pat = base:lower()
  for _, note in ipairs(notes) do
    if note.id:lower():find(pat, 1, true) or note.title:lower():find(pat, 1, true) then
      results[#results + 1] = {
        word  = note.id .. "]]",
        abbr  = note.id,
        menu  = note.title,
        icase = 1,
      }
    end
  end
  return results
end

-- ─── Setup ───────────────────────────────────────────────────────────────────

function M.setup()
  -- Try registering with nvim-cmp
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp then
    cmp.register_source("zk", cmp_source.new())
    -- Add zk to default sources for markdown
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        cmp.setup.buffer({
          sources = cmp.config.sources(
            { { name = "zk" }, { name = "buffer" }, { name = "path" } }
          ),
        })
      end,
    })
    return
  end

  -- Try blink.cmp
  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink and blink.add_provider then
    blink.add_provider("zk", blink_source.new())
    return
  end

  -- Omnifunc fallback
  vim.api.nvim_create_autocmd("FileType", {
    pattern  = "markdown",
    callback = function()
      vim.bo.omnifunc = ""
      -- Register custom omnifunc via lua
      vim.api.nvim_buf_create_user_command(0, "ZkOmni", function()
        vim.bo.omnifunc = "v:lua.require'zk.completion'.omnifunc"
      end, {})
      vim.bo.omnifunc = "v:lua.require'zk.completion'.omnifunc_wrapper"
    end,
  })
end

-- Expose for omnifunc assignment
M.omnifunc = omnifunc
function M.omnifunc_wrapper(findstart, base)
  return omnifunc(findstart, base)
end

return M
