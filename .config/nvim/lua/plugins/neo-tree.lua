return {
	"nvim-neo-tree/neo-tree.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle left<cr>", desc = "Toggle Neo-tree" },
	},
	opts = {
		sources         = { "filesystem", "buffers", "git_status" },
		default_source  = "filesystem",

		filesystem = {
			follow_current_file      = { enabled = true },
			bind_to_cwd              = true,
			group_empty_dirs         = true,
			use_libuv_file_watcher   = true,
		},

		window = {
			width    = 30,
			mappings = {
				["<cr>"] = "open",
				["l"]    = "open",
				["h"]    = "close_node",
				["a"]    = "add",
				["d"]    = "delete",
				["r"]    = "rename",
				["c"]    = "copy",
				["x"]    = "move",
				["p"]    = "paste_from_clipboard",
				["q"]    = "close_window",
                ["<space>"] = "none"
			},
		},
	},

	config = function(_, opts)
		require("neo-tree").setup(opts)
	end,
}

