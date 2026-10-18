-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-start `dune build -w` when opening OCaml files in a dune project.
-- Keeps one watcher per project root; tears down on nvim exit.
do
  local dune_jobs = {} -- root_dir -> job_id

  local function start_dune_watch(root_dir)
    if dune_jobs[root_dir] then
      return -- already running for this root
    end
    local cmd = { "sh", "-c", 'eval $(opam env) && exec dune build -w 2>&1' }
    local job_id = vim.fn.jobstart(cmd, {
      cwd = root_dir,
      detach = false,
      on_exit = function()
        dune_jobs[root_dir] = nil
      end,
    })
    if job_id > 0 then
      dune_jobs[root_dir] = job_id
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("dune_watch", { clear = true }),
    pattern = { "ocaml", "ocaml.interface", "dune" },
    callback = function()
      local root = vim.fs.root(0, { "dune-project" })
      if root then
        start_dune_watch(root)
      end
    end,
  })
end
