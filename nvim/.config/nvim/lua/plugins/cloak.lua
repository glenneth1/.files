return {
  "laytan/cloak.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>uc", "<cmd>CloakToggle<cr>", desc = "Toggle Cloak" },
  },
  config = function()
    require("cloak").setup({
      enabled = true,
      cloak_character = "*",
      highlight_group = "Comment",
      try_all_patterns = true,
      patterns = {
        -- dotenv / config secrets
        {
          file_pattern = { ".env*", "wrangler.toml", ".npmrc" },
          cloak_pattern = "=.+",
        },

        -- GPG files + authinfo
        {
          file_pattern = { "*.gpg", "*.asc", "*.pgp", ".authinfo*", ".netrc*" },
          cloak_pattern = {
            -- common authinfo/netrc-ish forms:
            -- "... password SECRET"
            "(password%s+).+",
            -- "... pass SECRET"
            "(pass%s+).+",
          },
          -- keep the keyword ("password " / "pass ") visible, cloak the rest
          replace = "%1",
        },
      },
    })

    -- If vim-gnupg decrypts via BufReadCmd, forcing CloakEnable on enter helps.
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
      pattern = { "*.gpg", "*.asc", "*.pgp" },
      callback = function()
        pcall(vim.cmd, "CloakEnable")
      end,
    })
  end,
}
