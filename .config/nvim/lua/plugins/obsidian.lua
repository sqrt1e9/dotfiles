return {
	"epwalsh/obsidian.nvim",
	lazy = false,
	version = "*",
	ft = { "markdown" },
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("obsidian").setup({
			dir = vim.fn.expand("~/Devworx/Notes"),
			workspaces = {
				{
					name = "Notes",
					path = "~/Devworx/Notes",
				},
			},
			completion = {
				nvim_cmp = true,
			},
			note_frontmatter_func = function(note)
				if note.title then
					note:add_alias(note.title)
				end

				local out = {
					title   = note.title,
					id      = note.id,
					aliases = note.aliases,
					tags    = note.tags,
				}

				if note.metadata and not vim.tbl_isempty(note.metadata) then
					for k, v in pairs(note.metadata) do
						out[k] = v
					end
				end

				return out
			end,
			new_note_location = "current_dir",
			templates = {
				subdir = ".",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M"
			},
		})
	end,
}

