return {

    -- add C to treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, { "c" })
        end,
    },

    -- lsp / dap extensions
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, { "clangd", "clangd-format" })
        end,
    },
}
