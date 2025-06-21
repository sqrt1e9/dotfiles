
local M = {}

function M.setup()
  vim.cmd([[
    iabbrev :ok ✅
    iabbrev :no ❌
    iabbrev :warn ⚠️
    iabbrev :info ℹ️
    iabbrev :next ➡️
    iabbrev :star ⭐
    iabbrev :dot 🔸
    iabbrev :spark ✨
    iabbrev :think 🤔
  ]])
end

return M

