local map = vim.keymap.set
local opts = { buffer = true, silent = true, noremap = true }

map("n", "<leader>rr", "<cmd>!cargo run<CR>", vim.tbl_extend("force", opts, { desc = "cargo_run" }))
map("n", "<leader>rt", "<cmd>!cargo test<CR>", vim.tbl_extend("force", opts, { desc = "cargo_test" }))
map("n", "<leader>rf", "<cmd>!cargo fmt<CR>", vim.tbl_extend("force", opts, { desc = "cargo_fmt" }))

local rt_ok, rt = pcall(require, "rust-tools")
if rt_ok then
    map("n", "<leader>rh", rt.hover_actions.hover_actions, vim.tbl_extend("force", opts, { desc = "hover_actions" }))
    map("n", "<leader>ra", rt.code_action_group.code_action_group, vim.tbl_extend("force", opts, { desc = "code_actions" }))
end

