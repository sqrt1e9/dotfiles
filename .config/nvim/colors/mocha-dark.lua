vim.cmd("highlight clear")
vim.cmd("set termguicolors")
vim.g.colors_name = "mocha"

local palette = {
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
	text      = "#cdd6f4",
	subtext1  = "#bac2de",
	subtext0  = "#a6adc8",
	overlay2  = "#9399b2",
	overlay1  = "#7f849c",
	overlay0  = "#6c7086",
	surface2  = "#585b70",
	surface1  = "#45475a",
	surface0  = "#313244",
	base      = "#1e1e2e",
	mantle    = "#181825",
	crust     = "#11111b",
}

local highlights = {
	-- Main UI
	Normal         = { fg = palette.text, bg = palette.crust },
	Visual         = { fg = palette.crust, bg = palette.lavender }, -- Bright Block
	Cursor         = { fg = palette.crust, bg = palette.rosewater },
	Search         = { fg = palette.crust, bg = palette.yellow },   -- Bright Block
	CurSearch      = { fg = palette.crust, bg = palette.peach },    -- Highlighted Match
	
	-- Statusline (The "Waybar" of Neovim)
	StatusLine     = { fg = palette.crust, bg = palette.blue },     -- Solid Blue Block
	StatusLineNC   = { fg = palette.overlay1, bg = palette.surface0 },
	
	-- Menus / Completion (Pills)
	Pmenu          = { fg = palette.text, bg = palette.surface0 },
	PmenuSel       = { fg = palette.crust, bg = palette.mauve },    -- Selected item block
	
	-- Syntax
	Comment        = { fg = palette.overlay2 },
	Constant       = { fg = palette.peach },
	String         = { fg = palette.green },
	Character      = { fg = palette.pink },
	Number         = { fg = palette.peach },
	Boolean        = { fg = palette.peach },
	Float          = { fg = palette.peach },
	Identifier     = { fg = palette.text },
	Function       = { fg = palette.blue },
	Statement      = { fg = palette.mauve },
	Conditional    = { fg = palette.mauve },
	Repeat         = { fg = palette.mauve },
	Label          = { fg = palette.mauve },
	Operator       = { fg = palette.sky },
	Keyword        = { fg = palette.mauve },
	Exception      = { fg = palette.red },
	PreProc        = { fg = palette.mauve },
	Include        = { fg = palette.red },
	Define         = { fg = palette.mauve },
	Macro          = { fg = palette.mauve },
	PreCondit      = { fg = palette.mauve },
	Type           = { fg = palette.yellow },
	StorageClass   = { fg = palette.mauve },
	Structure      = { fg = palette.yellow },
	Typedef        = { fg = palette.yellow },
	Special        = { fg = palette.red },
	SpecialChar    = { fg = palette.pink },
	Tag            = { fg = palette.blue },
	Delimiter      = { fg = palette.overlay2 },
	SpecialComment = { fg = palette.overlay2 },
	Debug          = { fg = palette.red },
	Underlined     = { style = "underline" },
	Error          = { fg = palette.red },
	Todo           = { fg = palette.teal, style = "bold" },
}

-- Apply Highlights
for group, opts in pairs(highlights) do
	local cmd = "highlight " .. group
	if opts.fg then cmd = cmd .. " guifg=" .. opts.fg end
	if opts.bg then cmd = cmd .. " guibg=" .. opts.bg end
	if opts.style then cmd = cmd .. " gui=" .. opts.style end
	vim.cmd(cmd)
end

-- Floating windows (Telescope / Popups)
vim.api.nvim_set_hl(0, "NormalFloat", { bg = palette.mantle }) -- Slightly different dark to pop
vim.api.nvim_set_hl(0, "FloatBorder", { bg = palette.mantle, fg = palette.blue })

-- Neo-tree / File Tree
vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = palette.blue })
vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = palette.blue })
vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = palette.blue, bold = true })

