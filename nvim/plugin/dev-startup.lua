-- Open Telescope file picker when launched via the dev() shell function.
-- Triggered by: SHELLSMITH_DEV=1 nvim
if vim.env.SHELLSMITH_DEV then
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.schedule(function()
        require("telescope.builtin").find_files()
      end)
    end,
  })
end
