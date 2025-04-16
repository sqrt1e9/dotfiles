vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require("jdtls").setup_jdtls()
		autocmd FileType rust lua require("rust")
    augroup end
]]

local function apply_jdtls_highlights()

    local palette = require("kanagawa.colors").setup({ theme = "wave" }).palette
	vim.api.nvim_set_hl(0, "@lsp.type.class",        { fg = palette.carpYellow })
	vim.api.nvim_set_hl(0, "@lsp.type.interface",    { fg = palette.boatYellow2 })
	vim.api.nvim_set_hl(0, "@lsp.type.enum",         { fg = palette.sumiInk3 })
	vim.api.nvim_set_hl(0, "@lsp.type.enumMember",   { fg = palette.surimiOrange, italic = true })
	vim.api.nvim_set_hl(0, "@lsp.type.constant",     { fg = palette.peachRed })
	vim.api.nvim_set_hl(0, "@lsp.type.property",     { fg = palette.autumnYellow })
	vim.api.nvim_set_hl(0, "@lsp.type.field",        { fg = palette.autumnYellow })
	vim.api.nvim_set_hl(0, "@lsp.type.method",       { fg = palette.waveBlue1 })
	vim.api.nvim_set_hl(0, "@method.call",           { fg = palette.waveBlue1 })
	vim.api.nvim_set_hl(0, "@lsp.type.parameter",    { fg = palette.fujiWhite })

	vim.api.nvim_set_hl(0, "@keyword.modifier.java", { fg = palette.fujiPurple })
	vim.api.nvim_set_hl(0, "@keyword.type.java",     { fg = palette.fujiPurple })
	vim.api.nvim_set_hl(0, "@type.definition.java",  { fg = palette.carpYellow })
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "jdtls" then
			vim.api.nvim_create_autocmd("User", {
				pattern = "LspTokenUpdate",
				callback = function()
					vim.defer_fn(apply_jdtls_highlights, 20)
				end,
			})
		end
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "kanagawa-wave",
    callback = function()
        vim.defer_fn(apply_jdtls_highlights, 50)
    end,
})
