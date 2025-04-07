return {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priorty = 1000,
    config = function()
        require("kanagawa").setup({
            theme = "wave",
            overrides = function(colors)
            return {
                ["@keyword"] = { fg = "#97989c" },
                ["@type"] = {}
            }
            end
        })
    end
}
