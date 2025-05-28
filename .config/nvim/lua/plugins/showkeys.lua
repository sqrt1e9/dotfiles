return {
	"nvzone/showkeys",
	lazy = false,
	opts = {
		timeout = 1,
		maxkeys = 3,
	},
	config = function(_, opts)
		require("showkeys").setup(opts)
		vim.cmd("ShowkeysToggle")
	end,
}

