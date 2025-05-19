return {
	{
		'nvim-telescope/telescope.nvim',
		lazy = false,
		tag = '0.1.6',
		dependencies = {
			'nvim-lua/plenary.nvim',
			'nvim-telescope/telescope-ui-select.nvim'
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local builtin = require("telescope.builtin")

			telescope.setup({
				defaults = {
					layout_strategy = "horizontal",
					layout_config = {
						horizontal = {
							width = 0.80,
							height = 0.75,
							prompt_position = "top",
							preview_width = 0.55,
						},
					},
					sorting_strategy = "ascending",
					winblend = 5,
					border = true,
					file_ignore_patterns = {
						"%.class$",
						"%.jar$",
						"%.iml$",
						"%.rs.bk$",
						"target/",
						"build/",
						"%.gradle/",
						"%.idea/",
						"%.git/",
						"%.mvn/",
						"%.settings/",
						"node_modules/"
					},
					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
						},
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({})
					}
				}
			})

			telescope.load_extension("ui-select")

			vim.keymap.set('n', '<leader>ff', builtin.find_files,           { desc = "find_files" })
			vim.keymap.set('n', '<leader>fg', builtin.live_grep,           { desc = "live_grep" })
			vim.keymap.set('n', '<leader>fd', builtin.diagnostics,         { desc = "diagnostics" })
			vim.keymap.set('n', '<leader>fr', builtin.resume,              { desc = "resume" })
			vim.keymap.set('n', '<leader>f.', builtin.oldfiles,            { desc = "recents" })
			vim.keymap.set('n', '<leader>fb', builtin.buffers,             { desc = "buffers" })
			vim.keymap.set('n', '<leader>cr', builtin.lsp_references,      { desc = "references" })
			vim.keymap.set('n', '<leader>ci', builtin.lsp_implementations, { desc = "implementations" })
		end
	}
}
