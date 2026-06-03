-- lua/zk/snacks.lua
-- Deep snacks.nvim integration — registered as snacks.picker source.
-- Usage: require("zk.snacks").notes()  etc., or via snacks.picker.pick("zk_notes")

local M = {}

local function cfg() return require("zk").config end
local index = require("zk.index")

-- ── Item builders ─────────────────────────────────────────────────────────────

local function note_to_item(note)
  local tags = #note.tags > 0 and (" [" .. table.concat(note.tags, ",") .. "]") or ""
  return {
    text  = note.title .. " " .. note.id .. tags,
    -- display columns
    title = note.title,
    date  = note.date,
    tags  = tags,
    file  = note.path,
    -- raw ref
    note  = note,
  }
end

-- ── Actions ───────────────────────────────────────────────────────────────────

local function action_open(picker, item)
  picker:close()
  if item then vim.cmd("edit " .. vim.fn.fnameescape(item.note.path)) end
end

local function action_insert_link(picker, item)
  picker:close()
  if not item then return end
  local link = string.format("[[%s]]", item.note.id)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { link })
  vim.api.nvim_win_set_cursor(0, { row, col + #link })
end

local function action_new_note(picker)
  local q = picker:get_query()
  picker:close()
  if q ~= "" then require("zk.notes").new_note(q) end
end

-- ── Picker factories ──────────────────────────────────────────────────────────

--- Note browser
function M.notes(opts)
  local ok, snacks = pcall(require, "snacks")
  if not ok then return end
  index.ensure()

  local items = vim.tbl_map(note_to_item, index.all())

  snacks.picker.pick(vim.tbl_deep_extend("force", {
    title   = "ZK Notes",
    items   = items,
    format  = function(item, _)
      return {
        { item.title, item.note and #item.note.links > 3 and "Special" or "Normal" },
        { "  " },
        { item.date,  "Comment" },
        { item.tags,  "Type" },
      }
    end,
    preview = function(ctx)
      local note = ctx.item and ctx.item.note
      if note then ctx.preview:show_file(note.path) end
    end,
    confirm = action_open,
    actions = {
      insert_link = { action = action_insert_link, desc = "Insert [[link]]" },
      new_note    = { action = action_new_note, desc = "New note from query" },
    },
    win     = {
      input = {
        keys = {
          ["<C-l>"] = { "insert_link", mode = { "i", "n" } },
          ["<C-n>"] = { "new_note", mode = { "i", "n" } },
        },
      },
    },
  }, opts or {}))
end

--- Backlinks for current note
function M.backlinks(opts)
  local ok, snacks = pcall(require, "snacks")
  if not ok then return end
  index.ensure()

  local path = vim.api.nvim_buf_get_name(0)
  local note = index._notes[path]
  if not note then
    vim.notify("[ZK] Not a tracked note", vim.log.levels.WARN)
    return
  end

  local bl = index.backlinks(note.id)
  if #bl == 0 then
    vim.notify("[ZK] No backlinks to: " .. note.title, vim.log.levels.INFO)
    return
  end

  local items = vim.tbl_map(note_to_item, bl)
  snacks.picker.pick(vim.tbl_deep_extend("force", {
    title   = "Backlinks → " .. note.title,
    items   = items,
    format  = function(item, _) return { { item.title, "Normal" }, { "  " }, { item.date, "Comment" } } end,
    preview = function(ctx)
      if ctx.item then ctx.preview:show_file(ctx.item.note.path) end
    end,
    confirm = action_open,
  }, opts or {}))
end

--- Tag browser
function M.tags(opts)
  local ok, snacks = pcall(require, "snacks")
  if not ok then return end
  index.ensure()

  local tags = index.all_tags()
  local tag_items = vim.tbl_map(function(tag)
    local count = #index.by_tag(tag)
    return {
      text  = tag,
      title = "#" .. tag,
      count = string.format("%d notes", count),
      tag   = tag,
    }
  end, tags)

  snacks.picker.pick(vim.tbl_deep_extend("force", {
    title   = "ZK Tags",
    items   = tag_items,
    format  = function(item, _)
      return {
        { item.title, "Type" },
        { "  " },
        { item.count, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.notes({
          title = "Tag: " .. item.title,
          -- pre-filter items to this tag
          items = vim.tbl_map(note_to_item, index.by_tag(item.tag))
        })
      end
    end,
  }, opts or {}))
end

return M
