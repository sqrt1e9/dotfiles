return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/nvim-cmp"
        },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "jdtls" },
            })
        end
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        lazy = false,
        config = function()
            require("mason-nvim-dap").setup({
                ensure_installed = { "java-debug-adapter", "java-test" }
            })
        end
    },
    {
        "mfussenegger/nvim-jdtls",
        lazy = false,
        dependencies = {
            "mfussenegger/nvim-dap",
        }
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
            })
            vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "hover" })
            vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "definition" })
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "code_actions" })
            vim.keymap.set("n", "<leader>cr", require("telescope.builtin").lsp_references, { desc = "references" })
            vim.keymap.set("n", "<leader>ci", require("telescope.builtin").lsp_implementations, { desc = "implementations" })
            vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "rename" })
            vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "declaration" })
        end
    }
}
