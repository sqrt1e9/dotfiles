vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require("jdtls").setup_jdtls()
		autocmd FileType rust lua require("rust")
        autocmd FileType xml setlocal foldmethod=syntax
    augroup end
]]

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("oil").open()
		end
	end,
})

