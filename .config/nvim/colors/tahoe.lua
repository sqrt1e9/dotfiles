-- liquid-glass tahoe (frosted + low-contrast, blur-friendly)
vim.cmd("highlight clear")
vim.opt.termguicolors = true
vim.g.colors_name = "tahoe"

-- Optional but strongly recommended for glass
vim.opt.winblend = 18
vim.opt.pumblend = 22

local palette = {
	-- accents
	rosewater = "#f5e0dc",
	flamingo  = "#f2cdcd",
	pink      = "#f5c2e7",
	mauve     = "#cba6f7",
	red       = "#f38ba8",
	maroon    = "#eba0ac",
	peach     = "#fab387",
	yellow    = "#f9e2af",
	green     = "#a6e3a1",
	teal      = "#94e2d5",
	sky       = "#89dceb",
	sapphire  = "#74c7ec",
	blue      = "#89b4fa",
	lavender  = "#b4befe",

	-- text
	text      = "#cdd6f4",
	subtext1  = "#bac2de",
	subtext0  = "#a6adc8",

	-- glass neutrals
	overlay2  = "#8f96b3",
	overlay1  = "#7a809b",
	overlay0  = "#656a83",

	surface2  = "#3a3f57",
	surface1  = "#2f3348",
	surface0  = "#24273a",

	base      = "#1e1e2e",
	mantle    = "#181825",
	crust     = "#11111b",

	-- extra UI tones
	glass_sel = "#1a2433",
	glass_pm  = "#121a25",
	glass_hi  = "#0f1520",
}

local function hl(group, spec)
	vim.api.nvim_set_hl(0, group, spec)
end

-- Core
hl("Normal",			{ fg = palette.text, bg = "NONE" })
hl("NormalNC",		{ fg = palette.subtext1, bg = "NONE" })

hl("Comment",		{ fg = palette.overlay1, italic = true })
hl("Constant",		{ fg = palette.peach })
hl("String",		{ fg = palette.green })
hl("Character",		{ fg = palette.pink })
hl("Number",		{ fg = palette.peach })
hl("Boolean",		{ fg = palette.peach })
hl("Float",			{ fg = palette.peach })

hl("Identifier",	{ fg = palette.text })
hl("Function",		{ fg = palette.blue })

hl("Statement",		{ fg = palette.mauve })
hl("Conditional",	{ fg = palette.mauve })
hl("Repeat",		{ fg = palette.mauve })
hl("Label",			{ fg = palette.mauve })
hl("Operator",		{ fg = palette.sky })
hl("Keyword",		{ fg = palette.mauve })
hl("Exception",		{ fg = palette.red })

hl("PreProc",		{ fg = palette.mauve })
hl("Include",		{ fg = palette.red })
hl("Define",		{ fg = palette.mauve })
hl("Macro",			{ fg = palette.mauve })
hl("PreCondit",		{ fg = palette.mauve })

hl("Type",			{ fg = palette.yellow })
hl("StorageClass",	{ fg = palette.mauve })
hl("Structure",		{ fg = palette.yellow })
hl("Typedef",		{ fg = palette.yellow })

hl("Special",		{ fg = palette.red })
hl("SpecialChar",	{ fg = palette.pink })
hl("Tag",			{ fg = palette.blue })
hl("Delimiter",		{ fg = palette.overlay2 })
hl("SpecialComment",{ fg = palette.overlay1 })
hl("Debug",			{ fg = palette.red })
hl("Underlined",	{ underline = true })
hl("Error",			{ fg = palette.red })
hl("Todo",			{ fg = palette.teal, bold = true })

-- UI / glass
hl("CursorLine",	{ bg = palette.glass_hi })
hl("CursorColumn",	{ bg = palette.glass_hi })
hl("Visual",		{ bg = palette.glass_sel })
hl("Search",		{ bg = palette.surface0, fg = palette.text })
hl("IncSearch",		{ bg = palette.surface1, fg = palette.text, bold = true })

hl("LineNr",		{ fg = palette.overlay0 })
hl("CursorLineNr",	{ fg = palette.lavender, bold = true })

hl("WinSeparator",	{ fg = palette.surface0 })
hl("VertSplit",		{ fg = palette.surface0 })

hl("StatusLine",	{ fg = palette.text, bg = "NONE" })
hl("StatusLineNC",	{ fg = palette.subtext0, bg = "NONE" })

-- Floating windows
hl("NormalFloat",	{ fg = palette.text, bg = "NONE" })
hl("FloatBorder",	{ fg = palette.overlay1, bg = "NONE" })
hl("FloatTitle",	{ fg = palette.subtext1, bg = "NONE" })

-- Completion menu
hl("Pmenu",			{ fg = palette.subtext1, bg = palette.glass_pm })
hl("PmenuSel",		{ fg = palette.text, bg = palette.surface0, bold = true })
hl("PmenuSbar",		{ bg = palette.surface0 })
hl("PmenuThumb",	{ bg = palette.overlay0 })

-- Diagnostics
hl("DiagnosticError", { fg = palette.red })
hl("DiagnosticWarn",	{ fg = palette.yellow })
hl("DiagnosticInfo",	{ fg = palette.sapphire })
hl("DiagnosticHint",	{ fg = palette.teal })

hl("DiagnosticUnderlineError", { undercurl = true, sp = palette.red })
hl("DiagnosticUnderlineWarn",	{ undercurl = true, sp = palette.yellow })
hl("DiagnosticUnderlineInfo",	{ undercurl = true, sp = palette.sapphire })
hl("DiagnosticUnderlineHint",	{ undercurl = true, sp = palette.teal })

-- Telescope / LSP
hl("TelescopeNormal",		{ fg = palette.text, bg = "NONE" })
hl("TelescopeBorder",		{ fg = palette.overlay1, bg = "NONE" })
hl("TelescopePromptBorder",{ fg = palette.overlay1, bg = "NONE" })
hl("TelescopeTitle",		{ fg = palette.subtext1, bg = "NONE" })
hl("TelescopeSelection",	{ bg = palette.surface0 })

hl("LspReferenceText",	{ bg = palette.surface0 })
hl("LspReferenceRead",	{ bg = palette.surface0 })
hl("LspReferenceWrite",{ bg = palette.surface0 })

hl("SignColumn", { bg = "NONE" })

