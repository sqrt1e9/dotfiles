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
vim.cmd [[
    hi Normal        guibg=none	ctermbg=none
    hi NormalFloat   guibg=none	ctermbg=none
    hi SignColumn    guibg=none	ctermbg=none
    hi LineNr        guibg=none	ctermbg=none
    hi EndOfBuffer   guibg=none	ctermbg=none
    hi NonText       guibg=none	ctermbg=none
    hi StatusLine    guibg=none	ctermbg=none
    hi StatusLineNC  guibg=none	ctermbg=none
    hi VertSplit     guibg=none	ctermbg=none
    hi TabLine       guibg=none	ctermbg=none
    hi TabLineFill   guibg=none	ctermbg=none
    hi TabLineSel    guibg=none	ctermbg=none
    hi Pmenu         guibg=none	ctermbg=none
    hi PmenuSel      guibg=none	ctermbg=none
    hi PmenuSbar     guibg=none	ctermbg=none
    hi PmenuThumb    guibg=none	ctermbg=none
]]


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
