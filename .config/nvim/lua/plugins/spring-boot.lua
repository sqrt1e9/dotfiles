return {
    "elmcgill/springboot-nvim",
    enabled = false,
    lazy = false,
    dependencies = {
        "neovim/nvim-lspconfig",
        "mfussenegger/nvim-jdtls"
    },
    config = function()
        local springboot_nvim = require("springboot-nvim")
        vim.keymap.set('n', '<leader>Jr', springboot_nvim.boot_run, { desc = "run" })
        springboot_nvim.setup({})
    end
}
