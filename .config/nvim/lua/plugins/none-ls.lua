return {
    "nvimtools/none-ls.nvim",
    lazy = false,
    dependencies = {
        "nvimtools/none-ls-extras.nvim",
    },
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.prettier,
                require("none-ls.diagnostics.eslint_d"),
                require("null-ls").builtins.formatting.prettier.with({
                    filetypes = { "xml" }
                }),
                require("null-ls").builtins.formatting.clang_format.with({
                    filetypes = { "c", "cpp" }
                })
            }
        })

        vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "code_format" })
    end
}
