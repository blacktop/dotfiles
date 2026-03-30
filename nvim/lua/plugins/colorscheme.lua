return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = { italic = true },
                variables = {},
                sidebars = "dark",
                floats = "dark",
            },
        },
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        opts = {
            flavour = "auto",
            background = {
                light = "latte",
                dark = "mocha",
            },
            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                loops = { "italic" },
                functions = { "italic" },
            },
            default_integrations = true,
            integrations = {
                blink_cmp = true,
                gitsigns = true,
                snacks = true,
                treesitter = true,
                mini = { enabled = true },
            },
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight",
        },
    },
}
