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
                ensure_installed = { "lua_ls", "jdtls", "lemminx" },
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
	    "WhoIsSethDaniel/mason-tool-installer.nvim",
	    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
	    config = function()
		    require("mason-tool-installer").setup({
			    ensure_installed = {
				"lemminx",
			    },
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
                capabilities = capabilities
            })
            lspconfig.lemminx.setup({
                cmd = { "lemminx" },
                filetypes = { "xml" }
            })
            vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "hover" })
            vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "definition" })
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "code_actions" })
            vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "rename" })
            vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "declaration" })
        end
    },
    {
        "simrat39/rust-tools.nvim",
        lazy = false,
        ft = "rust",
        config = function()
            local rt = require("rust-tools")
            rt.setup({
                server = {
                    on_attach = function(_, bufnr)
                    end
                }
            })
        end
    }
}
