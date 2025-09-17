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
			{ "<leader>c", group = "code"     },
			{ "<leader>d", group = "debug"    },
			{ "<leader>e", group = "explorer" },
			{ "<leader>f", group = "find"     },
			{ "<leader>g", group = "git"      },
			{ "<leader>J", group = "java"     },
			{ "<leader>r", group = "rust"     },
			{ "<leader>w", group = "window"   },
			{ "<leader>l", group = "latex"    },
			{ "<leader>m", group = "markdown" },

			{ "<leader>C",  name = "+C/C++" },
			{ "<leader>CC", "<cmd>lua compile_run_cpp()<CR>",		desc = "compile_run_cpp" },
			{ "<leader>CO", "<cmd>lua compile_run_cpp_omp()<CR>",	desc = "compile_run_cpp_omp" },
			{ "<leader>Cc", "<cmd>lua compile_run_c()<CR>",			desc = "compile_run_c" },
			{ "<leader>Co", "<cmd>lua compile_run_c_omp()<CR>",		desc = "compile_run_c_omp" },

			{ "<leader>o",  name = "+obsidian" },
			{ "<leader>of", "<cmd>ObsidianQuickSwitch<CR>",			desc = "find_note" },
			{ "<leader>on", "<cmd>ObsidianNew<CR>",					desc = "new_note" },
			{ "<leader>os", "<cmd>ObsidianSearch<CR>",				desc = "search_in_notes" },
			{ "<leader>ot", "<cmd>ObsidianToday<CR>",				desc = "todays_note" },
			{ "<leader>oy", "<cmd>ObsidianYesterday<CR>",			desc = "yesterdays_note" },
			{ "<leader>oT", "<cmd>ObsidianTemplate<CR>",				desc = "load_template" },
		})
	end
}

