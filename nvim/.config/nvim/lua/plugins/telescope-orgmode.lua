return {
  "nvim-orgmode/telescope-orgmode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-orgmode/orgmode",
    "folke/snacks.nvim",
  },
  config = function()
    local tom = require("telescope-orgmode")
    tom.setup({ adapter = "snacks" })

    vim.keymap.set("n", "<leader>fh", tom.search_headings, { desc = "Org headlines" })
    vim.keymap.set("n", "<leader>ft", tom.search_tags, { desc = "Org tags" })
    vim.keymap.set("n", "<leader>r", tom.refile_heading, { desc = "Org refile" })
    vim.keymap.set("n", "<leader>li", tom.insert_link, { desc = "Org insert link" })
  end,
}
