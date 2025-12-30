-----------------------------------------------------------
--  Pywal-based colorscheme for Neovim
--  Transparent background + Telescope friendly
-----------------------------------------------------------

vim.cmd("highlight clear")
vim.cmd("set termguicolors")
vim.g.colors_name = "mocha"

-----------------------------------------------------------
-- Load pywal colors
-----------------------------------------------------------
local wal_path = vim.fn.expand("~/.cache/wal/colors.json")

local ok, wal = pcall(function()
  return vim.fn.json_decode(vim.fn.readfile(wal_path))
end)

if not ok or not wal then
  vim.notify("Pywal colors not found. Run 'wal -i <image>'", vim.log.levels.WARN)
  return
end

-----------------------------------------------------------
-- Palette (pywal → semantic mapping)
-----------------------------------------------------------
local palette = {
  base   = wal.special.background,
  text   = wal.special.foreground,
  cursor = wal.special.cursor,

  black   = wal.colors.color0,
  red     = wal.colors.color1,
  green   = wal.colors.color2,
  yellow  = wal.colors.color3,
  blue    = wal.colors.color4,
  magenta = wal.colors.color5,
  cyan    = wal.colors.color6,
  white   = wal.colors.color7,

  overlay2 = wal.colors.color8,
  overlay1 = wal.colors.color7,
  surface0 = wal.colors.color0,
  crust    = wal.colors.color0,
}

-----------------------------------------------------------
-- Highlight groups
-----------------------------------------------------------
local highlights = {
  Normal         = { fg = palette.text, bg = palette.crust },
  Comment        = { fg = palette.overlay2 },
  Constant       = { fg = palette.yellow },
  String         = { fg = palette.green },
  Character      = { fg = palette.magenta },
  Number         = { fg = palette.yellow },
  Boolean        = { fg = palette.yellow },
  Float          = { fg = palette.yellow },
  Identifier     = { fg = palette.text },
  Function       = { fg = palette.blue },
  Statement      = { fg = palette.magenta },
  Conditional    = { fg = palette.magenta },
  Repeat         = { fg = palette.magenta },
  Label          = { fg = palette.magenta },
  Operator       = { fg = palette.cyan },
  Keyword        = { fg = palette.magenta },
  Exception      = { fg = palette.red },
  PreProc        = { fg = palette.magenta },
  Include        = { fg = palette.red },
  Define         = { fg = palette.magenta },
  Macro          = { fg = palette.magenta },
  Type           = { fg = palette.yellow },
  StorageClass   = { fg = palette.magenta },
  Structure      = { fg = palette.yellow },
  Typedef        = { fg = palette.yellow },
  Special        = { fg = palette.red },
  Tag            = { fg = palette.blue },
  Delimiter      = { fg = palette.overlay2 },
  Debug          = { fg = palette.red },
  Underlined     = { style = "underline" },
  Error          = { fg = palette.red },
  Todo           = { fg = palette.cyan, style = "bold" },
  StatusLine     = { fg = palette.text, bg = palette.crust },
  StatusLineNC   = { fg = palette.text, bg = palette.crust },
}

-----------------------------------------------------------
-- Apply highlights
-----------------------------------------------------------
for group, opts in pairs(highlights) do
  local cmd = "highlight " .. group
  if opts.fg then cmd = cmd .. " guifg=" .. opts.fg end
  if opts.bg then cmd = cmd .. " guibg=" .. opts.bg end
  if opts.style then cmd = cmd .. " gui=" .. opts.style end
  vim.cmd(cmd)
end

-----------------------------------------------------------
-- Floating windows (Telescope / LSP / etc.)
-----------------------------------------------------------
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", fg = palette.overlay2 })

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

