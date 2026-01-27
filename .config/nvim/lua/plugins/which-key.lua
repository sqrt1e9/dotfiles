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
			{ "<leader>/", group = "comments"  },
			{ "<leader>c", group = "code"      },
			{ "<leader>d", group = "debug"     },
			{ "<leader>e", group = "explorer"  },
			{ "<leader>f", group = "find"      },
			{ "<leader>g", group = "git"       },
			{ "<leader>J", group = "java"      },
			{ "<leader>r", group = "rust"      },
			{ "<leader>w", group = "window"    },
			{ "<leader>l", group = "latex"     },
			{ "<leader>m", group = "markdown"  },

			-- C / C++
			{ "<leader>C",  name = "+C/C++" },
			{ "<leader>Cc", "<cmd>lua compile_c_cpp()<CR>",			desc = "compile" },
			{ "<leader>Cr", "<cmd>lua run_c_cpp()<CR>",				desc = "run (stdin)" },
			{ "<leader>Ca", "<cmd>lua compile_and_run_c_cpp()<CR>",	desc = "compile + run" },

			-- Obsidian
			{ "<leader>o",  name = "+obsidian" },
			{ "<leader>of", "<cmd>ObsidianQuickSwitch<CR>",	desc = "find note" },
			{ "<leader>on", "<cmd>ObsidianNew<CR>",			desc = "new note" },
			{ "<leader>os", "<cmd>ObsidianSearch<CR>",			desc = "search notes" },
			{ "<leader>ot", "<cmd>ObsidianToday<CR>",			desc = "today note" },
			{ "<leader>oy", "<cmd>ObsidianYesterday<CR>",		desc = "yesterday note" },
			{ "<leader>oT", "<cmd>ObsidianTemplate<CR>",		desc = "load template" },
		})
	end
}

