return {
	"epwalsh/obsidian.nvim",
    lazy = false,
	version	= "*",
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "Notes",
				path = "~/Devworx/Notes",
			},
		},
		completion = {
			nvim_cmp = true,
		},
        note_formatter_fun = function(note)
            return {
                aliases = note.aliases,
                tag = note.tags
            }
        end,
        new_note_location = "current_dir",
        templates = {
            subdir = "Templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
            default = "markdown.md"
        }
	},
}

