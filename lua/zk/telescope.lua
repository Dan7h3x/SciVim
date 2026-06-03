-- lua/zk/telescope.lua
-- Optional Telescope extension: telescope.load_extension("zk")
-- Provides :Telescope zk notes/backlinks/tags/grep

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then return {} end

local pickers       = require("telescope.pickers")
local finders       = require("telescope.finders")
local conf          = require("telescope.config").values
local actions       = require("telescope.actions")
local astate        = require("telescope.actions.state")
local previewers    = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

local index         = require("zk.index")

local function cfg() return require("zk").config end

-- ── Entry maker ───────────────────────────────────────────────────────────────

local function make_entry(note)
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 36 },
      { width = 12 },
      { remaining = true },
    },
  })

  local function display(entry)
    local n = entry.value
    return displayer({
      { n.title,                   "TelescopeResultsIdentifier" },
      { n.date or "",              "TelescopeResultsNumber" },
      { table.concat(n.tags, " "), "TelescopeResultsComment" },
    })
  end

  return {
    value   = note,
    ordinal = note.title .. " " .. note.id .. " " .. table.concat(note.tags, " "),
    display = display,
    path    = note.path,
  }
end

-- ── Shared previewer ──────────────────────────────────────────────────────────

local function note_previewer()
  return previewers.new_buffer_previewer({
    title = "Note Preview",
    define_preview = function(self, entry)
      if entry.path and vim.fn.filereadable(entry.path) == 1 then
        conf.buffer_previewer_maker(entry.path, self.state.bufnr, {
          bufname = entry.path,
          winid   = self.state.winid,
        })
      end
    end,
  })
end

-- ── Pickers ───────────────────────────────────────────────────────────────────

local function zk_notes(opts)
  opts = opts or {}
  index.ensure()
  local notes = index.all()

  pickers.new(opts, {
    prompt_title    = "ZK Notes",
    finder          = finders.new_table({
      results     = notes,
      entry_maker = make_entry,
    }),
    sorter          = conf.generic_sorter(opts),
    previewer       = note_previewer(),
    attach_mappings = function(buf, map)
      -- default: open note
      actions.select_default:replace(function()
        actions.close(buf)
        local sel = astate.get_selected_entry()
        if sel then vim.cmd("edit " .. vim.fn.fnameescape(sel.path)) end
      end)

      -- <C-l>: insert link
      map("i", "<C-l>", function()
        local sel = astate.get_selected_entry()
        if not sel then return end
        actions.close(buf)
        local link = string.format("[[%s]]", sel.value.id)
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { link })
        vim.api.nvim_win_set_cursor(0, { row, col + #link })
      end)

      -- <C-n>: new note with current query as title
      map("i", "<C-n>", function()
        local q = astate.get_current_line()
        actions.close(buf)
        if q ~= "" then require("zk.notes").new_note(q) end
      end)

      return true
    end,
  }):find()
end

local function zk_backlinks(opts)
  opts = opts or {}
  index.ensure()

  local path = vim.api.nvim_buf_get_name(0)
  local note = index._notes[path]
  if not note then
    vim.notify("[ZK] Not a tracked note", vim.log.levels.WARN)
    return
  end

  local bl = index.backlinks(note.id)
  if #bl == 0 then
    vim.notify("[ZK] No backlinks", vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
    prompt_title    = "Backlinks → " .. note.title,
    finder          = finders.new_table({ results = bl, entry_maker = make_entry }),
    sorter          = conf.generic_sorter(opts),
    previewer       = note_previewer(),
    attach_mappings = function(buf, _)
      actions.select_default:replace(function()
        actions.close(buf)
        local sel = astate.get_selected_entry()
        if sel then vim.cmd("edit " .. vim.fn.fnameescape(sel.path)) end
      end)
      return true
    end,
  }):find()
end

local function zk_tags(opts)
  opts = opts or {}
  index.ensure()

  local tags = index.all_tags()
  local entries = vim.tbl_map(function(tag)
    local notes = index.by_tag(tag)
    return {
      value   = tag,
      ordinal = tag,
      display = string.format("#%-30s  %d", tag, #notes),
      count   = #notes,
    }
  end, tags)

  pickers.new(opts, {
    prompt_title    = "ZK Tags",
    finder          = finders.new_table({ results = entries }),
    sorter          = conf.generic_sorter(opts),
    attach_mappings = function(buf, _)
      actions.select_default:replace(function()
        actions.close(buf)
        local sel = astate.get_selected_entry()
        if sel then
          -- open second picker for notes with this tag
          zk_notes(vim.tbl_extend("force", opts, {
            default_text = "#" .. sel.value,
          }))
        end
      end)
      return true
    end,
  }):find()
end

local function zk_grep(opts)
  opts = opts or {}
  require("telescope.builtin").live_grep(vim.tbl_extend("force", {
    prompt_title = "ZK Grep",
    cwd          = cfg().dir,
    glob_pattern = "*.md",
  }, opts))
end

-- ── Extension registration ────────────────────────────────────────────────────

return telescope.register_extension({
  exports = {
    notes     = zk_notes,
    backlinks = zk_backlinks,
    tags      = zk_tags,
    grep      = zk_grep,
    -- entry point: :Telescope zk  (lists sub-commands)
    zk        = zk_notes,
  },
})
