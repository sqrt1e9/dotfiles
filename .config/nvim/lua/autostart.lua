vim.cmd [[
    augroup jdtls_lsp
        autocmd!
        autocmd FileType java lua require("jdtls").setup_jdtls()
    augroup end
]]

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
    pattern = "*.java",
    callback = function()
        vim.defer_fn(function()
            if not require("nvim-treesitter.parsers").has_parser("java") then return end
            vim.treesitter.start()
        end, 50)
    end,
})
