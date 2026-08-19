-- Workaround: the vim treesitter grammar doesn't define "tab" as a node,
-- but the highlights.scm query references it, causing parse errors.
-- We patch the plugin file directly and use pin=true so lazy won't
-- overwrite our fix on updates. Run :TSUpdate manually when needed,
-- then this build hook will re-apply the patch.
return {
  "nvim-treesitter/nvim-treesitter",
  pin = true,
  build = function()
    local path = vim.fn.stdpath("data")
      .. "/lazy/nvim-treesitter/runtime/queries/vim/highlights.scm"
    local f = io.open(path, "r")
    if not f then
      return
    end
    local content = f:read("*a")
    f:close()
    local patched = content:gsub('\n%s*"tab"\n', "\n")
    if patched ~= content then
      local fw = io.open(path, "w")
      if fw then
        fw:write(patched)
        fw:close()
      end
    end
  end,
}
