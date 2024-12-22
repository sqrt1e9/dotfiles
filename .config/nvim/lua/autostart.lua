vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require("jdtls").setup_jdtls()
    augroup end
]]
