return {
	'folke/which-key.nvim',
	dependencies = {
		"echasnovski/mini.icons"
	},
	lazy = false,
	event = "VeryLazy",
	config = function()
		local which_key = require('which-key')
		which_key.setup()

		which_key.add({
			{ "<leader>/", group = "comments" },
			{ "<leader>c", group = "code" },
			{ "<leader>d", group = "debug" },
			{ "<leader>e", group = "explorer" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>J", group = "java" },
            { "<leader>r", group = "rust" },
			{ "<leader>w", group = "window" },
			{ "<leader>l", group = "latex" },
			{ "<leader>r", group = "rust" },
            { "<leader>m", group = "markdown" }
		})
	end
}
