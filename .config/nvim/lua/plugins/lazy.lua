return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp"
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "lemminx", "rust_analyzer" },
			})
		end
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		lazy = false,
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = { "java-debug-adapter", "java-test" }
			})
		end
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"lemminx",
					"rust-analyzer",
				},
			})
		end
	},
	{
		"mfussenegger/nvim-jdtls",
		lazy = false,
		dependencies = {
			"mfussenegger/nvim-dap",
		}
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig		= require("lspconfig")
			local capabilities	= require("cmp_nvim_lsp").default_capabilities()

			-- Lua LSP
			lspconfig.lua_ls.setup({
				capabilities = capabilities
			})

			-- XML (lemminx)
			lspconfig.lemminx.setup({
				cmd = { "lemminx" },
				filetypes = { "xml" }
			})

			-- C/C++ (clangd)
			lspconfig.clangd.setup({
				capabilities = capabilities,
				cmd = {
					"clangd",
					"--background-index",             -- keep an index for fast lookups
					"--clang-tidy",                   -- run clang-tidy diagnostics
					"--completion-style=detailed",
					"--header-insertion=iwyu",        -- smart #include insertion
					"--all-scopes-completion",
					-- ensure clangd trusts your system compilers
					"--query-driver=/usr/bin/clang++,/usr/bin/g++"
				},
				-- If you use compile_commands.json (CMake), clangd will auto-pick it up.
				-- Otherwise, fall back to compile_flags.txt or .clangd configs.
				root_dir = lspconfig.util.root_pattern(
					"compile_commands.json",
					"compile_flags.txt",
					".git"
				)
			})

			-- Common LSP keymaps
			vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover,        { desc = "hover" })
			vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition,   { desc = "definition" })
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "code_actions" })
			vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename,       { desc = "rename" })
			vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration,  { desc = "declaration" })
		end
	},
	{
		"simrat39/rust-tools.nvim",
		lazy = false,
		ft = "rust",
		config = function()
			local rt			= require("rust-tools")
			local capabilities	= require("cmp_nvim_lsp").default_capabilities()
			local util			= require("lspconfig.util")

			rt.setup({
				server = {
					capabilities = capabilities,
					root_dir = util.root_pattern("Cargo.toml"),
					on_attach = function(_, bufnr)
						local map	= vim.keymap.set
						local opts	= { buffer = bufnr, silent = true, noremap = true }

						map("n", "<leader>rr", "<cmd>!cargo run<CR>", vim.tbl_extend("force", opts, { desc = "cargo_run" }))
						map("n", "<leader>rt", "<cmd>!cargo test<CR>", vim.tbl_extend("force", opts, { desc = "cargo_test" }))
						map("n", "<leader>rf", "<cmd>!cargo fmt<CR>", vim.tbl_extend("force", opts, { desc = "cargo_fmt" }))

						map("n", "<leader>rh", rt.hover_actions.hover_actions, vim.tbl_extend("force", opts, { desc = "hover_actions" }))
						map("n", "<leader>ra", rt.code_action_group.code_action_group, vim.tbl_extend("force", opts, { desc = "code_actions" }))
					end
				}
			})
		end
	},
	{
		"preservim/vim-markdown",
		lazy = false,
		ft = "markdown",
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "markdown" },
		config = function()
			require("render-markdown").setup({})
		end
	}
}

