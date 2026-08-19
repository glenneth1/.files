-- Sextant - Common Lisp Language Server
-- https://github.com/parenworks/sextant
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")
      if not configs.sextant then
        configs.sextant = {
          default_config = {
            cmd = { "/home/glenn/SourceCode/sextant/sextant" },
            filetypes = { "lisp" },
            root_dir = function(fname)
              return require("lspconfig.util").find_git_ancestor(fname)
                or vim.fn.getcwd()
            end,
            settings = {},
          },
        }
      end
      require("lspconfig").sextant.setup({})
    end,
  },
}
