vim.cmd("highlight clear")
vim.cmd("set termguicolors")

vim.opt.background = "light"
vim.g.colors_name = "mocha"

local wal_path = vim.fn.expand("~/.cache/wal/colors.json")

local ok, wal = pcall(function()
	return vim.fn.json_decode(vim.fn.readfile(wal_path))
end)

if not ok or not wal then
	vim.notify(
		"Pywal colors not found. Run 'wal -i <image>'",
		vim.log.levels.WARN
	)
	return
end

local palette = {
	base      = "#eff1f5",
	text      = "#202020",
	cursor    = wal.special.cursor,

	black     = wal.colors.color0,
	red       = wal.colors.color1,
	green     = wal.colors.color2,
	yellow    = wal.colors.color3,
	blue      = wal.colors.color4,
	magenta   = wal.colors.color5,
	cyan      = wal.colors.color6,
	white     = wal.colors.color7,

	overlay2  = "#6a6a6a",
	overlay1  = "#8a8a8a",

	surface0  = wal.colors.color7,
	crust     = wal.colors.color7,

    accent    = wal.colors.color5,
    accent2   = wal.colors.color4,
}

-----------------------------------------------------------
-- Highlight Groups
-----------------------------------------------------------

local highlights = {
	Normal         = { fg = palette.text, bg = palette.base },
    Function       = { fg = palette.blue, style = "bold" },
    Keyword        = { fg = palette.magenta, style = "bold" },
    Type           = { fg = palette.blue },
    String         = { fg = palette.green },
    Number         = { fg = palette.red },
    Comment        = { fg = palette.overlay2, style = "italic" }  ,
	Constant       = { fg = palette.red },
	Character      = { fg = palette.magenta },
	Boolean        = { fg = palette.yellow },
	Float          = { fg = palette.yellow },
	Identifier     = { fg = palette.text },
	Statement      = { fg = palette.magenta },
	Conditional    = { fg = palette.magenta },
	Repeat         = { fg = palette.magenta },
	Label          = { fg = palette.magenta },
	Operator       = { fg = palette.cyan },
	Exception      = { fg = palette.red },
	PreProc        = { fg = palette.magenta },
	Include        = { fg = palette.red },
	Define         = { fg = palette.magenta },
	Macro          = { fg = palette.magenta },
	StorageClass   = { fg = palette.magenta },
	Structure      = { fg = palette.cyan },
	Typedef        = { fg = palette.cyan },
	Special        = { fg = palette.red },
	Tag            = { fg = palette.blue },
	Delimiter      = { fg = palette.overlay2 },
	Debug          = { fg = palette.red },
	Underlined     = { style = "underline" },
	Error          = { fg = palette.red, style = "bold" },
	Todo           = { fg = palette.cyan, style = "bold" },
	StatusLine     = { fg = palette.text, bg = palette.crust },
	StatusLineNC   = { fg = palette.overlay2, bg = palette.crust },
	LineNr         = { fg = palette.overlay1 },
	CursorLineNr   = { fg = palette.accent, style = "bold" },
	Visual         = { bg = palette.accent },
	Search         = {
		fg = palette.text,
		bg = palette.accent,
	},

	IncSearch      = {
		fg = palette.text,
		bg = palette.accent2,
	},

	Pmenu          = {
		fg = palette.text,
		bg = palette.surface0,
	},

	PmenuSel       = {
		fg = palette.text,
		bg = palette.accent,
	},
}

for group, opts in pairs(highlights) do
	local cmd = "highlight " .. group

	if opts.fg then
		cmd = cmd .. " guifg=" .. opts.fg
	end

	if opts.bg then
		cmd = cmd .. " guibg=" .. opts.bg
	end

	if opts.style then
		cmd = cmd .. " gui=" .. opts.style
	end

	vim.cmd(cmd)
end

vim.api.nvim_set_hl(0, "NormalFloat", {
	fg = palette.text,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "FloatBorder", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "Cursor", {
	fg = "#ffffff",
	bg = palette.accent,
})

vim.api.nvim_set_hl(0, "CursorLine", {
	bg = "#f7f7f7",
})

vim.api.nvim_set_hl(0, "CursorColumn", {
	bg = "#f5f5f5",
})

vim.api.nvim_set_hl(0, "TelescopeNormal", {
	fg = palette.text,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopeBorder", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePromptNormal", {
	fg = palette.text,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePromptBorder", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopeResultsNormal", {
	fg = palette.text,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopeResultsBorder", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePreviewNormal", {
	fg = palette.text,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePreviewBorder", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePromptPrefix", {
	fg = palette.accent,
	bg = palette.base,
})

vim.api.nvim_set_hl(0, "TelescopePreviewTitle", {
	fg = "#ffffff",
	bg = palette.accent,
	bold = true,
})

vim.api.nvim_set_hl(0, "TelescopeResultsTitle", {
	fg = "#ffffff",
	bg = palette.accent,
	bold = true,
})

vim.api.nvim_set_hl(0, "TelescopeSelection", {
	fg = "#ffffff",
	bg = palette.accent,
	bold = true,
})

vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", {
	fg = "#ffffff",
	bg = palette.accent,
})

vim.api.nvim_set_hl(0, "WinSeparator", {
	fg = palette.accent,
})

_G.WalPalette = palette
