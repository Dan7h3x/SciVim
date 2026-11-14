local util = require("fly.util")

---@type fly.Source
local M = {
  title = "grep",
  live = true,
  icons = true,
  defaults = { min_query = 2, max_results = 5000, regex = true },
}

local function command(opts, query)
  if vim.fn.executable("rg") == 1 then
    local cmd = {
      "rg", "--vimgrep", "--no-heading", "--color=never", "--smart-case",
      "--max-columns=300", "--max-columns-preview", "-g", "!.git",
    }
    if opts.hidden then
      cmd[#cmd + 1] = "--hidden"
    end
    if opts.ignored then
      cmd[#cmd + 1] = "--no-ignore"
    end
    if opts.follow then
      cmd[#cmd + 1] = "--follow"
    end
    if opts.regex == false then
      cmd[#cmd + 1] = "--fixed-strings"
    end
    vim.list_extend(cmd, opts.args or {})
    -- `-e` makes a leading dash safe; the explicit path stops rg from reading stdin
    vim.list_extend(cmd, { "-e", query, "." })
    return cmd, true
  end
  local cmd = { "grep", "-rnIH", "--exclude-dir=.git", opts.regex == false and "-F" or "-E" }
  if query == query:lower() then
    cmd[#cmd + 1] = "-i" -- emulate smart-case
  end
  vim.list_extend(cmd, opts.args or {})
  vim.list_extend(cmd, { "-e", query, "." })
  return cmd, false
end

function M.start(ctx, push, done)
  local query = ctx.query
  if #query < (ctx.opts.min_query or 2) then
    done()
    return
  end
  local cmd, is_rg = command(ctx.opts, query)
  local max = ctx.opts.max_results or 5000
  local count = 0
  local lq = query:lower()
  local proc
  proc = util.stream(cmd, { cwd = ctx.cwd }, function(lines)
    local items = {}
    for _, line in ipairs(lines) do
      local path, lnum, col, text
      if is_rg then
        path, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
      else
        path, lnum, text = line:match("^(.-):(%d+):(.*)$")
        -- plain grep has no column: locate the query ourselves
        col = text and ((text:lower():find(lq, 1, true)) or 1) or 1
      end
      if path then
        path = path:gsub("^%./", "")
        col = tonumber(col)
        local trimmed = text:gsub("^%s+", "")
        local lead = #text - #trimmed
        local pos = ("%s:%s:%d"):format(path, lnum, col)
        local display = pos .. "  " .. trimmed
        local hl = { { #path, #pos, "FlyExtra" } }
        local end_col
        local ms = col - lead
        if ms >= 1 and trimmed:sub(ms, ms + #query - 1):lower() == lq then
          hl[#hl + 1] = { #pos + 2 + ms - 1, #pos + 2 + ms - 1 + #query, "FlyMatch" }
          end_col = col + #query
        end
        items[#items + 1] = {
          label = ("%s:%s"):format(path, lnum),
          display = display,
          hl = hl,
          text = trimmed,
          path = vim.fs.joinpath(ctx.cwd, path),
          line = tonumber(lnum),
          col = col,
          end_col = end_col,
          kind = "grep",
        }
        count = count + 1
        if count >= max then
          break
        end
      end
    end
    push(items)
    if count >= max then
      proc.kill()
      done()
    end
  end, function(code, stderr)
    if code == -1 then
      util.warn("could not run grep: " .. stderr)
    end
    done() -- exit code 2 is usually a half-typed regex: stay quiet
  end)
  return proc
end

M.keys = { ["<M-r>"] = "toggle_regex" }

M.actions = {
  toggle_regex = function(p)
    p.opts.regex = p.opts.regex == false
    p:run_source()
    util.notify("grep: " .. (p.opts.regex and "regex" or "literal") .. " mode")
  end,
}

return M
