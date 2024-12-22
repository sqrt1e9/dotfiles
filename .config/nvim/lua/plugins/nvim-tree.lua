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
        })
    end
}
