vim.cmd [[
	augroup lsp_setup
		autocmd!
		autocmd FileType java     lua require("jdtls").setup_jdtls()
		autocmd FileType rust     lua require("rust")
		autocmd FileType markdown lua require("md")
		autocmd FileType markdown setlocal foldmethod=expr
		autocmd FileType markdown setlocal foldexpr=nvim_treesitter#foldexpr()
	augroup end
]]

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("oil").open()
		end
	end,
})

local function apply_highlights()
	local palette = require("kanagawa.colors").setup({ theme = "wave" }).palette
	local theme = require("kanagawa.colors").setup({ theme = "wave" }).theme

    local groups = {

        ["@variable"]                            = { fg = palette.fujiWhite },
		["@variable.parameter"]                  = { fg = palette.fujiWhite },
		["@lsp.typemod.variable.definition"]     = { fg = palette.fujiWhite },
		["@lsp.typemod.variable.readonly"]       = { fg = palette.fujiWhite },
		["@variable.builtin"]                    = { fg = palette.peachRed },
		["@variable.member"]                     = { fg = palette.autumnYellow },
		["@variable.global"]                     = { fg = palette.autumnYellow },

		["@function"]                            = { fg = palette.crystalBlue },
		["@function.call"]                       = { fg = palette.crystalBlue },
		["@method"]                              = { fg = palette.crystalBlue },
		["@method.call"]                         = { fg = palette.crystalBlue },

		["@field"]                               = { fg = palette.autumnYellow },
		["@property"]                            = { fg = palette.autumnYellow },

		["@markup.heading.1.markdown"]           = { fg = palette.crystalBlue,    bold = true },
		["@markup.heading.2.markdown"]           = { fg = palette.sakuraPink,     bold = true },
		["@markup.heading.3.markdown"]           = { fg = palette.boatYellow2,    bold = true, bg = "NONE" },
		["@markup.heading.4.markdown"]           = { fg = palette.springGreen,    bold = true },
    	["@markup.heading.5.markdown"]           = { fg = palette.waveAqua2,      bold = true },
		["@markup.heading.6.markdown"]           = { fg = palette.fujiGray,       bold = true },

		["@markup.italic.markdown"]              = { fg = palette.crystalBlue },
		["@markup.list.markdown"]                = { fg = palette.peachRed },
		["@markup.link.markdown"]                = { fg = palette.springBlue,     underline = true },
		["@markup.quote.markdown"]               = { fg = palette.boatYellow2 },
		["@markup.raw.markdown_inline"]          = { fg = palette.surimiOrange },
		["@markup.math"]                         = { fg = palette.fujiWhite },
		["@text.markdown"]                       = { fg = palette.fujiPurple },
		["@markup.markdown"]                     = { fg = palette.fujiWhite },

		["@comment"]                             = { fg = theme.syn.comment },
		["@keyword"]                             = { fg = theme.syn.keyword },
		["@keyword.function"]                    = { fg = theme.syn.keyword },
		["@keyword.operator"]                    = { fg = theme.syn.operator },
		["@keyword.return"]                      = { fg = theme.syn.keyword },
	}

	for group, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "rust", "markdown", "lua" },
	callback = function(args)
		local ft = vim.api.nvim_buf_get_option(args.buf, "filetype")
		if ft == "markdown" then
			vim.diagnostic.disable(args.buf)
			vim.schedule(function()
				vim.diagnostic.reset(nil, args.buf)
			end)
			vim.defer_fn(function()
				local ok, renderer = pcall(require, "render-markdown")
				if ok then renderer.toggle() end
				apply_highlights()
			end, 100)
		elseif ft == "rust" or ft == "java" or ft == "lua" then
			vim.defer_fn(apply_highlights, 100)
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            client.server_capabilities.semanticTokensProvider = nil
        end
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        for _, group in ipairs(vim.fn.getcompletion("", "highlight")) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
            if ok and hl and hl.italic then
                hl.italic = false
                vim.api.nvim_set_hl(0, group, hl)
            end
        end
    end,
})

vim.cmd("doautocmd ColorScheme")
