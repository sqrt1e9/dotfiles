vim.cmd [[
	augroup lsp_setup
		autocmd!
		autocmd FileType java     lua require("jdtls").setup_jdtls()
		autocmd FileType rust     lua require("rust")
        autocmd FileType cpp      lua require("clang")
        autocmd FileType c        lua require("clang")
		autocmd FileType markdown lua require("md")
		autocmd FileType markdown setlocal foldmethod=expr
		autocmd FileType markdown setlocal foldexpr=nvim_treesitter#foldexpr()
	augroup end
]]

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			vim.cmd("Neotree show left")
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			client.server_capabilities.semanticTokensProvider = nil
		end
	end,
})

vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.md",
	callback = function()
		vim.bo.modifiable = true
	end,
})

vim.cmd("doautocmd ColorScheme")
vim.cmd("doautocmd User NeoTreeOpened")
