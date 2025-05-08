vim.cmd [[
	augroup lsp_setup
		autocmd!
		autocmd FileType java lua require("jdtls").setup_jdtls()
		autocmd FileType rust lua require("rust")
	augroup END
]]

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("oil").open()
		end
	end,
})

local function apply_global_no_italics()
	for _, group in ipairs(vim.fn.getcompletion("@", "highlight")) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
		if ok and hl and hl.italic then
			hl.italic = false
			vim.api.nvim_set_hl(0, group, hl)
		end
	end
end

local function apply_rust_colors()
	local palette = require("kanagawa.colors").setup({ theme = "wave" }).palette

	local rust_hls = {
		["@variable"]                        = { fg = palette.autumnYellow },
		["@variable.parameter"]              = { fg = palette.fujiWhite },
		["@lsp.typemod.variable.definition"] = { fg = palette.fujiWhite },
		["@function"]                        = { fg = palette.crystalBlue },
		["@method"]                          = { fg = palette.crystalBlue },
		["@field"]                           = { fg = palette.autumnYellow },
		["@property"]                        = { fg = palette.autumnYellow },
		["@variable.member"]                 = { fg = palette.autumnYellow },
		["@variable.builtin"]                = { fg = palette.peachRed },
	}

	for group, opts in pairs(rust_hls) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

local function rust_only_setup()
	apply_global_no_italics()
	apply_rust_colors()
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "rust",
	callback = function()
		vim.defer_fn(rust_only_setup, 50)
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		if client and client.name == "rust_analyzer" and ft == "rust" then
			vim.defer_fn(rust_only_setup, 50)
		end
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		apply_global_no_italics()
	end,
})

