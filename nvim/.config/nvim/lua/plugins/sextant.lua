-- Sextant - Common Lisp Language Server
-- https://github.com/parenworks/sextant
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")
      if not configs.sextant then
        local util = require("lspconfig.util")
        configs.sextant = {
          default_config = {
            cmd = { "/home/glenn/SourceCode/sextant/sextant" },
            filetypes = { "lisp", "commonlisp" },
            root_dir = function(fname)
              return util.root_pattern(".git", "*.asd", "*.asdf")(fname) or util.path.dirname(fname)
            end,
            settings = {},
          },
        }
      end
      require("lspconfig").sextant.setup({})
    end,
  },
}
