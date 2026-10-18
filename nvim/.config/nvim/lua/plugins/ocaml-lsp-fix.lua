-- ocamllsp is installed via opam, not Mason.
-- Skip Mason's installation attempts; the opam-installed
-- ocamllsp on PATH is used directly by lspconfig.
return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(name)
        return name ~= "ocamllsp" and name ~= "ocamlformat"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(name)
        return name ~= "ocamllsp"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ocamllsp = {
          mason = false,
        },
      },
    },
  },
}
