return {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 1000,
    config = function()
        require("notify").setup({
            render = "compact",
            stages = "static",
            timeout = 2000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
            on_open = function(win)
                vim.api.nvim_win_set_config(win, { focusable = false })
            end,
        })

        vim.keymap.set("n", "<leader>un", function()
            notify.dismiss({ silent = true, pending = true })
        end, {
            noremap = true,
            silent = true,
            desc = "Delete all Notifications",
        })
    end,
}
