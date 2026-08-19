return {
  "nvim-orgmode/orgmode",
  event = "VeryLazy",
  ft = { "org" },
  config = function()
    local function centered_menu(data)
      local content = {}
      local keys = {}
      local max_width = #(data.title or "")

      for _, item in ipairs(data.items) do
        if item.key then
          keys[item.key] = item
          local line = string.format("  %s  ➜  %s  ", item.key, item.label)
          if #line > max_width then max_width = #line end
          table.insert(content, line)
        end
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, content)

      local width = math.min(max_width + 2, math.floor(vim.o.columns * 0.6))
      local height = #content
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)

      local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " " .. (data.title or "Org") .. " ",
        title_pos = "center",
        zindex = 1000,
        focusable = false,
        noautocmd = true,
      })
      vim.cmd.redraw()

      local char = vim.fn.nr2char(vim.fn.getchar())
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
      vim.cmd.redraw()

      local entry = keys[char]
      if entry and entry.action then
        return entry.action()
      end
    end

    require("orgmode").setup({
      org_agenda_files = "~/orgfiles/**/*",
      org_default_notes_file = "~/orgfiles/refile.org",
      ui = {
        menu = {
          handler = centered_menu,
        },
      },
    })

    pcall(vim.lsp.enable, "org")
  end,
}
