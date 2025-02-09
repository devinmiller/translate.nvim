vim.api.nvim_create_user_command("TranslateSelection", function()
  require("translate").translate()
end, {})
