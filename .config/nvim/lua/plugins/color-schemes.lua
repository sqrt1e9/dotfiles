return {
	"rebelot/kanagawa.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("kanagawa").setup({
			theme = "wave",
			overrides = function(colors)
				local theme = colors.theme
				return {
				    ["@comment"] = { fg = theme.syn.comment, italic = false },
					["@keyword"] = { fg = theme.syn.keyword, italic = false },
					["@keyword.function"] = { fg = theme.syn.keyword, italic = false },
					["@keyword.operator"] = { fg = theme.syn.operator, italic = false },
                    ["@keyword.return"] = { italic = false },
					["@type.qualifier"] = { italic = false },
					["@lsp.type.comment"] = { italic = false },
					["@lsp.type.keyword"] = { italic = false },
					["@lsp.mod.readonly"] = { italic = false },
					["@lsp.mod.static"] = { italic = false },
					["@lsp.typemod.variable.readonly"] = { italic = false },
				}
			end
		})
		vim.cmd.colorscheme("kanagawa-wave")
	end
}

