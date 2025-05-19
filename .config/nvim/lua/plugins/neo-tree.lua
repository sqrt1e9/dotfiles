return {
	"nvim-neo-tree/neo-tree.nvim",
	branch      = "v3.x",
	lazy        = false,
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
			filtered_items = {
				visible           = false,
				hide_dotfiles     = true,
				hide_gitignored  = true,
				hide_by_pattern  = {
					"^target$", "^build$", "%.class$", "%.jar$", "%.iml$", "%.rs.bk$",
					"^%.gradle$", "^%.idea$", "^%.settings$", "^node_modules$"
				},
			},
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
				["p"]    = "paste",
				["q"]    = "close_window",
			},
		},
		default_component_configs = {
			container = {
				enable_character_fade = true,
			},
			indent = {
				indent_size         = 2,
				padding             = 1,
				with_markers        = true,
				indent_marker       = "│",
				last_indent_marker  = "└",
				highlight           = "NeoTreeIndentMarker",
				with_expanders      = nil,
				expander_collapsed  = "",
				expander_expanded   = "",
				expander_highlight  = "NeoTreeExpander",
			},
			icon = {
				folder_closed = "",
				folder_open   = "",
				folder_empty  = "",
				default       = "",
				highlight     = "NeoTreeFileIcon",
			},
			name = {
				trailing_slash         = false,
				use_git_status_colors  = true,
				highlight              = "NeoTreeFileName",
			},
			git_status = {
				symbols = {
					added     = "A",
					modified  = "M",
					deleted   = "D",
					renamed   = "R",
					untracked = "U",
					ignored   = "I",
					unstaged  = "!",
					staged    = "+",
					conflict  = "×",
				},
				align = "right",
			},
		},
	},
}
