return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons"
    },
    lazy = false,
    config = function()
        vim.keymap.set('n', '<leader>e', "<cmd>NvimTreeToggle<CR>", { desc = "toggle_explorer" })
        require("nvim-tree").setup({
            hijack_netrw = true,
            auto_reload_on_write = true,
            renderer = {
                highlight_git = true,
                icons = {
                    git_placement = "before",
                    show = {
                        git = false
                    }
                }
            },
            git = {
                enable = true
            }
        })
    end
}
