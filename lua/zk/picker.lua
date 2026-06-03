-- lua/zk/picker.lua
-- Unified picker facade: snacks.nvim > fzf-lua > telescope > vim.ui.select

local M = {}
local index = require("zk.index")

local function cfg() return require("zk").config end

-- ─── Backend detection ───────────────────────────────────────────────────────

---@return "snacks"|"fzf"|"telescope"|"vim"
local function detect_picker()
  local preferred = cfg().picker
  if preferred then return preferred end
  if pcall(require, "snacks") and require("snacks").picker then return "snacks" end
  if pcall(require, "fzf-lua") then return "fzf" end
  if pcall(require, "telescope") then return "telescope" end
  return "vim"
end

-- ─── Format helpers ──────────────────────────────────────────────────────────

---@param note ZkNote
---@return string
local function note_display(note)
  local tags = #note.tags > 0 and (" [" .. table.concat(note.tags, ", ") .. "]") or ""
  return string.format("%-40s  %s  %s", note.title, note.date, tags)
end

-- ─── Generic open helper ─────────────────────────────────────────────────────

local function open_path(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- ─── Snacks picker ───────────────────────────────────────────────────────────

local snacks = {}

function snacks.pick(items, opts, on_select)
  local snacks_mod = require("snacks")
  snacks_mod.picker.pick({
    title   = opts.title or "ZK",
    items   = items,
    format  = function(item) return { { item.display, "Normal" } } end,
    confirm = function(picker, item)
      picker:close()
      if item then on_select(item.data) end
    end,
    preview = opts.preview or function(ctx)
      local note = ctx.item and ctx.item.data
      if note and note.path then
        ctx.preview:show_file(note.path)
      end
    end,
  })
end

function snacks.grep(query, dir)
  local snacks_mod = require("snacks")
  snacks_mod.picker.grep({
    title   = "ZK Grep",
    cwd     = dir,
    initial = query,
    confirm = function(picker, item)
      picker:close()
      if item then open_path(item.file) end
    end,
  })
end

-- ─── fzf-lua picker ──────────────────────────────────────────────────────────

local fzf = {}

function fzf.pick(items, opts, on_select)
  local fzf_mod = require("fzf-lua")
  local entries = {}
  local map = {}
  for _, item in ipairs(items) do
    local key = item.display
    entries[#entries + 1] = key
    map[key] = item.data
  end

  fzf_mod.fzf_exec(entries, {
    prompt    = (opts.title or "ZK") .. "> ",
    previewer = opts.preview_cmd or false,
    fzf_opts  = { ["--no-sort"] = "" },
    actions   = {
      ["default"] = function(selected)
        if selected and selected[1] then
          on_select(map[selected[1]])
        end
      end,
    },
  })
end

function fzf.grep(query, dir)
  local fzf_mod = require("fzf-lua")
  fzf_mod.live_grep({
    cwd    = dir,
    query  = query or "",
    prompt = "ZK Grep> ",
  })
end

-- ─── Telescope picker ────────────────────────────────────────────────────────

local tele = {}

function tele.pick(items, opts, on_select)
  local pickers    = require("telescope.pickers")
  local finders    = require("telescope.finders")
  local conf       = require("telescope.config").values
  local actions    = require("telescope.actions")
  local astate     = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers.new({}, {
    prompt_title    = opts.title or "ZK",
    finder          = finders.new_table({
      results = items,
      entry_maker = function(item)
        return {
          value   = item.data,
          display = item.display,
          ordinal = item.display,
          path    = item.data.path,
        }
      end,
    }),
    sorter          = conf.generic_sorter({}),
    previewer       = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        if entry.path then
          conf.buffer_previewer_maker(entry.path, self.state.bufnr, {})
        end
      end,
    }),
    attach_mappings = function(buf, _)
      actions.select_default:replace(function()
        actions.close(buf)
        local sel = astate.get_selected_entry()
        if sel then on_select(sel.value) end
      end)
      return true
    end,
  }):find()
end

function tele.grep(query, dir)
  require("telescope.builtin").live_grep({
    prompt_title = "ZK Grep",
    cwd          = dir,
    default_text = query or "",
  })
end

-- ─── vim.ui.select fallback ──────────────────────────────────────────────────

local vimui = {}

function vimui.pick(items, opts, on_select)
  vim.ui.select(items, {
    prompt      = opts.title or "ZK: ",
    format_item = function(item) return item.display end,
  }, function(item)
    if item then on_select(item.data) end
  end)
end

function vimui.grep(query, dir)
  vim.ui.input({ prompt = "Grep pattern: ", default = query or "" }, function(pat)
    if not pat or pat == "" then return end
    vim.cmd(string.format("silent grep! %s %s/**/*.md | copen", vim.fn.shellescape(pat), dir))
  end)
end

-- ─── Dispatcher ──────────────────────────────────────────────────────────────

local backends = { snacks = snacks, fzf = fzf, telescope = tele, vim = vimui }

local function backend()
  return backends[detect_picker()] or vimui
end

local function pick(items, opts, on_select)
  if #items == 0 then
    vim.notify("[ZK] No notes found", vim.log.levels.WARN)
    return
  end
  backend().pick(items, opts, on_select)
end

-- ─── Public actions ──────────────────────────────────────────────────────────

--- Browse and open any note
function M.find_notes()
  local notes = index.all()
  local items = vim.tbl_map(function(n)
    return { display = note_display(n), data = n }
  end, notes)

  pick(items, { title = "ZK Notes" }, function(note)
    open_path(note.path)
  end)
end

--- Full-text grep across vault
---@param query? string
function M.grep_notes(query)
  backend().grep(query, cfg().dir)
end

--- Show notes that link to current note
function M.backlinks()
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

  local items = vim.tbl_map(function(n)
    return { display = note_display(n), data = n }
  end, bl)

  pick(items, { title = "Backlinks → " .. note.title }, function(n)
    open_path(n.path)
  end)
end

--- Pick a note and insert [[wikilink]] at cursor
function M.insert_link()
  local notes = index.all()
  local items = vim.tbl_map(function(n)
    return { display = note_display(n), data = n }
  end, notes)

  pick(items, { title = "Insert link" }, function(note)
    local link = string.format("[[%s]]", note.id)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { link })
    vim.api.nvim_win_set_cursor(0, { row, col + #link })
  end)
end

--- Browse by tag
function M.find_by_tag()
  local tags = index.all_tags()
  if #tags == 0 then
    vim.notify("[ZK] No tags found", vim.log.levels.WARN)
    return
  end

  local tag_items = vim.tbl_map(function(t)
    local count = #index.by_tag(t)
    return { display = string.format("#%-30s  %d notes", t, count), data = t }
  end, tags)

  pick(tag_items, { title = "ZK Tags" }, function(tag)
    local notes = index.by_tag(tag)
    local items = vim.tbl_map(function(n)
      return { display = note_display(n), data = n }
    end, notes)
    pick(items, { title = "Tag: #" .. tag }, function(note)
      open_path(note.path)
    end)
  end)
end

return M
