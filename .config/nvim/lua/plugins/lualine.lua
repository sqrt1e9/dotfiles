return {
	"nvim-lualine/lualine.nvim",
	lazy = false,

	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},

	config = function()
		local palette = _G.WalPalette

		require("lualine").setup({
			options = {
				icons_enabled = true,

				theme = {
					normal = {
						a = { fg = "#ffffff", bg = palette.accent, gui = "bold" },
						b = { fg = palette.text, bg = "#dce0e8" },
						c = { fg = palette.text, bg = palette.base },
					},

					insert = {
						a = { fg = "#ffffff", bg = palette.green, gui = "bold" },
					},

					visual = {
						a = { fg = "#ffffff", bg = palette.blue, gui = "bold" },
					},

					replace = {
						a = { fg = "#ffffff", bg = palette.red, gui = "bold" },
					},

					command = {
						a = { fg = "#ffffff", bg = palette.yellow, gui = "bold" },
					},

					inactive = {
						a = { fg = palette.overlay1, bg = palette.base },
						b = { fg = palette.overlay1, bg = palette.base },
						c = { fg = palette.overlay1, bg = palette.base },
					},
				},

				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },

				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},

				ignore_focus = { "NvimTree" },
				always_divide_middle = true,
				globalstatus = false,

				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},

			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = {},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},

			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},

			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
