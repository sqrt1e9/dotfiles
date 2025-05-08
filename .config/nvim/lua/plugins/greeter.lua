return {
	"goolord/alpha-nvim",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.startify")

		-- Optionally set sections here *before setup*
		dashboard.section.header.val = {
			"Welcome to BigoBrains",
			"🚀 Build. Think. Scale.",
			"",
		}

		alpha.setup(dashboard.config)
	end,
}

