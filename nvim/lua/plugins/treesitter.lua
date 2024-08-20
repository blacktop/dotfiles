return {
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "windwp/nvim-ts-autotag",
        },
        build = ":TSUpdate",
        config = function()
            local config = require("nvim-treesitter.configs")
            ---@diagnostic disable-next-line: missing-fields
            config.setup({
                ensure_installed = {
                    "arduino",
                    "awk",
                    "bash",
                    "cpp",
                    "css",
                    "csv",
                    "diff",
                    "dockerfile",
                    "fish",
                    "git_config",
                    "git_rebase",
                    "gitattributes",
                    "gitcommit",
                    "gitignore",
                    "go",
                    "gomod",
                    "gosum",
                    "gowork",
                    "graphql",
                    "hcl",
                    "html",
                    "http",
                    "http",
                    "ini",
                    "javascript",
                    "jq",
                    "json",
                    "lua",
                    "make",
                    "markdown",
                    "markdown_inline",
                    "nix",
                    "python",
                    "query",
                    "regex",
                    "ruby",
                    "rust",
                    "scss",
                    "sql",
                    "ssh_config",
                    "terraform",
                    "toml",
                    "vhs",
                    "vim",
                    "vimdoc",
                    "yaml",
                    "zig",
                },
                sync_install = false,
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                autotag = { enable = true },
            })
        end,
    },
}
