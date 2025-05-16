return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio"
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        dapui.setup()
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "toggle_breakpoint" })
        vim.keymap.set("n", "<leader>ds", dap.continue, { desc = "continue" })
        vim.keymap.set("n", "<leader>dc", dapui.close, {desc = "close"})
    end
}
