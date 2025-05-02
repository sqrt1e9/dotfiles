return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        dependencies = {
            "windwp/nvim-ts-autotag"
        },
        build = ':TSUpdate',
        config = function()
            local ts_config = require("nvim-treesitter.configs")
            ts_config.setup({
                ensure_installed = {
                    "vim",
                    "vimdoc",
                    "lua",
                    "java",
                    "javascript",
                    "typescript",
                    "xml",
                    "html",
                    "css",
                    "json",
                    "tsx",
                    "markdown",
                    "markdown_inline",
                    "gitignore",
                    "rust"
                },
                highlight = { enable = true },
                autotag = {
                    enable = true
                },
            })
        end
    },
    {
        "nvim-treesitter/playground",
        lazy = false,
        cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
        config = function()
            require("nvim-treesitter.configs").setup({
                playground = {
                    enable = true,
                    updatetime = 25,
                    persist_queries = false
                }
            })
        end
    }
}
