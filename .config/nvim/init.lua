local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

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

vim.opt.rtp:prepend(lazypath)

vim.g.c_compiler   = "gcc"
vim.g.cpp_compiler = "clang++"
vim.o.scrolloff = 3


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
    git = {
        url_format = "git@github.com:%s.git"
    }
}

require("options")
require("keymaps")
require("emoji")
require("lazy").setup("plugins", options)
require("autostart")
