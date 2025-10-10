return {
	"rebelot/kanagawa.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("kanagawa").setup({
			theme = "dragon",
            colors = {
                palette = {
                    fujiWhite = "#C5C9D2"
                }
            }
        })
		vim.cmd("colorscheme kanagawa-dragon")
	end
}

