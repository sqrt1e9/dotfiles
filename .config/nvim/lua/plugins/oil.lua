return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		default_file_explorer = true,
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name, _)
				local ignore_patterns = {
					"^target$", "^build$", "%.class$", "%.jar$", "%.iml$", "%.rs.bk$",
					"^%.gradle$", "^%.idea$", "^%.settings$", "^node_modules$"
				}
				for _, pattern in ipairs(ignore_patterns) do
					if name:match(pattern) then
						return true
					end
				end
				return false
			end,
		},
        keymaps = {
            ["<BS>"] = "actions.parent",
            ["q"] = "actions.close"
        }
	},
}
