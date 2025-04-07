-- Declare the path for Lazy clone
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Clone Lazy if not exists already
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

-- Add lazy to the VIM path
vim.opt.rtp:prepend(lazypath)

-- Default options for Lazy
local options = {
    defaults = {
        lazy = true
    },
    install = {
        colorSchemes = "kanagawa"
    },
    rtp = {
        dislabled_plugins = {
            "gzip",
            "netrw",
            "netrwPlugin"
        }
    },
	change_detection = {
		notify = false,
	},
	checker = {
		-- Auto Updates
		enabled = true,
		notify = false,
	},
}

require("options")
require("keymaps")
require("lazy").setup("plugins", options)

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        vim.cmd.colorscheme("kanagawa-wave")
    end
})

require("autostart")
