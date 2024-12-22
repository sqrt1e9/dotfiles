return {
    {
        "lewis6991/gitsigns.nvim",
        lazy = false,
        config = function()
            require("gitsigns").setup({})
            vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", {desc="[G]it Preview [H]unk"})
        end
    },
    {
        "tpope/vim-fugitive",
        lazy = false,
        config = function()
            vim.keymap.set("n", "<leader>gb", ":Git blame<cr>", { desc = "blame" })
            vim.keymap.set("n", "<leader>gA", ":Git add .<cr>", { desc = "add_all" })
            vim.keymap.set("n", "<leader>ga", "Git add", { desc = "add" })
            vim.keymap.set("n", "<leader>gc", ":Git commit", { desc = "commit" })
            vim.keymap.set("n", "<leader>gp", "Git push", { desc = "push" })
        end
    }
}
