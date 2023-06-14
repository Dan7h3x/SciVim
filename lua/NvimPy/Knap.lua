--[[
-- Knap Settings
--]]
local gknapsettings = {
	htmloutputext = "html",
	htmltohtml = "none",
	htmltohtmlviewerlaunch = "chromium %outputfile%",
	htmltohtmlviewerrefresh = "none",
	mdoutputext = "html",
	mdtohtml = "pandoc --standalone %docroot% -o %outputfile%",
	mdtohtmlviewerlaunch = "chromium %outputfile%",
	mdtohtmlviewerrefresh = "none",
	mdtopdf = "pandoc %docroot% -o %outputfile%",
	mdtopdfviewerlaunch = "sioyek %outputfile%",
	mdtopdfviewerrefresh = "none",
	markdownoutputext = "html",
	markdowntohtml = "pandoc --standalone %docroot% -o %outputfile%",
	markdowntohtmlviewerlaunch = "chromium %outputfile%",
	markdowntohtmlviewerrefresh = "none",
	markdowntopdf = "pandoc %docroot% -o %outputfile%",
	markdowntopdfviewerlaunch = "sioyek %outputfile%",
	markdowntopdfviewerrefresh = "none",
	texoutputext = "pdf",
	textopdf = "pdflatex -interaction=batchmode -halt-on-error -synctex=1 %docroot%",
	textopdfviewerlaunch = "sioyek --inverse-search 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%1'\"'\"',%2,%3)\"' --new-window %outputfile%",
	-- textopdfviewerlaunch = "zathura --synctex-editor-command 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%{input}'\"'\"',%{line},0)\"' %outputfile%",
	textopdfviewerrefresh = "none",
	textopdfforwardjump = "sioyek --inverse-search 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%1'\"'\"',%2,%3)\"' --reuse-window --forward-search-file %srcfile% --forward-search-line %line% %outputfile%",
	-- textopdfforwardjump = "zathura --synctex-forward=%line%:%column%:%srcfile% %outputfile%",
	textopdfshorterror = 'A=%outputfile% ; LOGFILE="${A%.pdf}.log" ; rubber-info "$LOGFILE" 2>&1 | head -n 1',
	delay = 250,
}

_G.xelatexcheck = function()
	local isxelatex = false
	local fifteenlines = vim.api.nvim_buf_get_lines(0, 0, 15, false)
	for l, line in ipairs(fifteenlines) do
		if
			(line:lower():match("xelatex"))
			or (line:match("\\usepackage[^}]*mathspec"))
			or (line:match("\\usepackage[^}]*fontspec"))
			or (line:match("\\usepackage[^}]*unicode-math"))
		then
			isxelatex = true
			break
		end
	end
	if isxelatex then
		local knapsettings = vim.b.knap_settings or {}
		knapsettings["textopdf"] = "xelatex -interaction=batchmode -halt-on-error -synctex=1 %docroot%"
		vim.b.knap_settings = knapsettings
	end
end
vim.api.nvim_create_autocmd({ "BufRead" }, { pattern = { "*.tex" }, callback = xelatexcheck })

vim.g.knap_settings = gknapsettings
