return {
    {
        'nvim-telescope/telescope.nvim',
        lazy = false,
        tag = '0.1.6',
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        config = function()
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "find_files" })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "live_grep" })
            vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = "diagnostics" })
            vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = "resume" })
            vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = "recents" })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "buffers" })
        end
    },
    {
        'nvim-telescope/telescope-ui-select.nvim',
        lazy = false,
        config = function()
            local actions = require("telescope.actions")

            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {}
                    }
                },
                mappings = {
                    i = {
                        ["<C-n>"] = actions.cycle_history_next,
                        ["<C-p>"] = actions.cycle_history_prev,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                    }
                },
                require("telescope").load_extension("ui-select")
            })
        end
    }
}
