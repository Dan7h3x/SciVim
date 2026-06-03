-- lua/zk/template.lua
-- Extensible template engine.
-- Templates can be Lua functions, strings with {{var}} placeholders, or files.

local M = {}

local function cfg() return require("zk").config end

--- Built-in templates
M.builtins = {

  default = function(ctx)
    return string.format([[---
id: %s
title: %s
date: %s
tags: []
---

# %s

]], ctx.id, ctx.title, ctx.date, ctx.title)
  end,

  daily = function(ctx)
    return string.format([[---
id: %s
title: Daily %s
date: %s
tags: [daily]
---

# %s

## 🎯 Focus

-

## 📝 Notes

## ✅ Tasks

- [ ]

## 🔗 Links

]], ctx.id, ctx.date, ctx.date, ctx.date)
  end,

  meeting = function(ctx)
    return string.format([[---
id: %s
title: %s
date: %s
tags: [meeting]
attendees: []
---

# %s

**Date:** %s
**Attendees:**

## Agenda

## Notes

## Action items

- [ ]

]], ctx.id, ctx.title, ctx.date, ctx.title, ctx.date)
  end,

  literature = function(ctx)
    return string.format([[---
id: %s
title: %s
date: %s
tags: [literature]
source:
author:
---

# %s

## Summary

## Key ideas

## Quotes

## My thoughts

]], ctx.id, ctx.title, ctx.date, ctx.title)
  end,

  fleeting = function(ctx)
    return string.format([[---
id: %s
title: %s
date: %s
tags: [fleeting]
---

# %s

]], ctx.id, ctx.title, ctx.date, ctx.title)
  end,
}

--- Expand a string template with {{var}} substitution
---@param tmpl string
---@param ctx table
---@return string
local function expand_string(tmpl, ctx)
  return (tmpl:gsub("{{(%w+)}}", function(key)
    return tostring(ctx[key] or "")
  end))
end

--- Load template from file path
---@param path string
---@param ctx table
---@return string?
local function load_file_template(path, ctx)
  local fd = io.open(path, "r")
  if not fd then return nil end
  local content = fd:read("*a")
  fd:close()
  return expand_string(content, ctx)
end

--- Render a template for a new note
---@param kind? string template kind (default, daily, meeting, ...)
---@param ctx table { id, title, date }
---@return string
function M.render(kind, ctx)
  kind = kind or "default"
  ctx.date = ctx.date or os.date("%Y-%m-%d")

  local templates = vim.tbl_deep_extend("force", M.builtins, cfg().templates or {})

  -- Check for template directory first
  local tmpl_dir = cfg().template_dir
  if tmpl_dir then
    local file_path = tmpl_dir .. "/" .. kind .. ".md"
    local result = load_file_template(file_path, ctx)
    if result then return result end
  end

  local tmpl = templates[kind] or templates["default"]
  if not tmpl then
    return string.format("---\nid: %s\ntitle: %s\ndate: %s\n---\n\n# %s\n\n",
      ctx.id, ctx.title, ctx.date, ctx.title)
  end

  if type(tmpl) == "function" then
    return tmpl(ctx)
  elseif type(tmpl) == "string" then
    return expand_string(tmpl, ctx)
  end

  return ""
end

--- Interactive template picker — lets user choose a template type
---@param callback fun(kind: string)
function M.pick(callback)
  local templates = vim.tbl_deep_extend("force", M.builtins, require("zk").config.templates or {})
  local kinds = vim.tbl_keys(templates)
  table.sort(kinds)

  vim.ui.select(kinds, {
    prompt = "Note template: ",
    format_item = function(k) return k end,
  }, function(choice)
    if choice then callback(choice) end
  end)
end

return M
