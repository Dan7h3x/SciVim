local M = {}

function M.highlights(colors, opts)
  return {
    -- Basic editor highlights
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.popup_back },
    FloatBorder = { fg = colors.float_border, bg = colors.popup_back },
    Cursor = { fg = colors.bg, bg = colors.fg },
    CursorLine = { bg = colors.cursor_line },
    CursorLineNr = { fg = colors.fg, bold = true },
    LineNr = { fg = colors.line_numbers },
    -- ... other core editor highlights

    -- Syntax highlighting
    Comment = { fg = colors.comment, italic = opts.styles.comments.italic },
    Constant = { fg = colors.const },
    String = { fg = colors.string, italic = opts.styles.strings.italic },
    Function = { fg = colors.func, bold = opts.styles.functions.bold },
    Keyword = { fg = colors.keyword, italic = opts.styles.keywords.italic, bold = opts.styles.keywords.bold },
    Type = { fg = colors.type, italic = opts.styles.types.italic, bold = opts.styles.types.bold },
    -- ... other syntax highlights
  }
end

return M