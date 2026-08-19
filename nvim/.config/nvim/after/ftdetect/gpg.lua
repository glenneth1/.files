-- If vim-gnupg intercepts reading (BufReadCmd), normal ftdetect may not fire.
-- This ensures encrypted files always get filetype=gpg.
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.gpg", "*.asc", "*.pgp" },
  callback = function()
    if vim.bo.filetype == "" then
      vim.bo.filetype = "gpg"
    end
  end,
})
