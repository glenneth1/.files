return {
  {
    "jamessan/vim-gnupg",
    lazy = false, -- IMPORTANT: must be loaded before reading *.gpg
    init = function()
      vim.g.gnupg_ext = ".gpg"
      vim.g.gnupg_autostart = 1
    end,
  },
}
