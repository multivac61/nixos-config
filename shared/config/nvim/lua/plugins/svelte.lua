return {

    -- add svelte to treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, { "svelte", "prisma", "sql" })
        end,
    },

    -- correctly setup mason lsp / dap extensions
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                svelte,
                prismals,
                tailwindcss,
            },
        },
    },
}
