-- Conjure - Interactive evaluation for Lisp, Clojure, Scheme, etc.
-- https://github.com/Olical/conjure
return {
  {
    "Olical/conjure",
    ft = { "clojure", "fennel", "scheme", "racket", "janet", "lua", "python", "rust", "sql" },
    lazy = true,
    init = function()
      -- Conjure configuration (set before plugin loads)
      
      -- Disable the default "HUD" floating window (can be noisy)
      -- Set to 1 to enable if you prefer it
      vim.g["conjure#log#hud#enabled"] = false
      
      -- Auto-repl behavior
      vim.g["conjure#extract#tree_sitter#enabled"] = true
      
      -- Common Lisp specific settings (for SBCL/Sly/Slynk)
      vim.g["conjure#client#lisp#swank#connection#default_host"] = "127.0.0.1"
      vim.g["conjure#client#lisp#swank#connection#default_port"] = 4005
      
      -- Auto-connect when a Lisp file is opened (if Slynk is running)
      vim.g["conjure#client#lisp#swank#connection#auto_repl#enabled"] = true
      
      -- Mappings prefix (default is <localleader> which is usually \)
      vim.g["conjure#mapping#prefix"] = "<localleader>"
    end,
    dependencies = {
      -- Structural editing for S-expressions (parens, brackets, etc.)
      {
        "gpanders/nvim-parinfer",
        ft = { "clojure", "fennel", "lisp", "scheme", "racket", "janet" },
      },
      -- S-expression text objects and motions
      {
        "julienvincent/nvim-paredit",
        ft = { "clojure", "fennel", "lisp", "scheme", "racket", "janet" },
        opts = {},
      },
    },
  },

  -- nvlime - SLIME-like CL environment (disabled, enable if needed)
  {
    "monkoose/nvlime",
    ft = { "lisp" },
    dependencies = { "monkoose/parsley.nvim" },
    enabled = false,
  },

  -- Treesitter parsers for Lisp languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, {
        "clojure",
        "fennel",
        "commonlisp",
      })
    end,
  },

  -- Rainbow delimiters for nested parens (very helpful for Lisp)
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
          commonlisp = rainbow.strategy["global"],
          clojure = rainbow.strategy["global"],
          fennel = rainbow.strategy["global"],
          scheme = rainbow.strategy["global"],
        },
        query = {
          [""] = "rainbow-delimiters",
          commonlisp = "rainbow-delimiters",
        },
      }
    end,
  },
}
