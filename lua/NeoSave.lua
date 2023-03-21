--[[

 /$$   /$$                      /$$$$$$
| $$$ | $$                     /$$__  $$
| $$$$| $$  /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$  /$$    /$$ /$$$$$$
| $$ $$ $$ /$$__  $$ /$$__  $$|  $$$$$$  |____  $$|  $$  /$$//$$__  $$
| $$  $$$$| $$$$$$$$| $$  \ $$ \____  $$  /$$$$$$$ \  $$/$$/| $$$$$$$$
| $$\  $$$| $$_____/| $$  | $$ /$$  \ $$ /$$__  $$  \  $$$/ | $$_____/
| $$ \  $$|  $$$$$$$|  $$$$$$/|  $$$$$$/|  $$$$$$$   \  $/  |  $$$$$$$
|__/  \__/ \_______/ \______/  \______/  \_______/    \_/    \_______/

--]]
local M = {}
local fn = vim.fn
local cmd = vim.cmd
local timer = vim.loop.new_timer()
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local user_cmd = vim.api.nvim_create_user_command

-- Configuration
M.config = {
  enabled = true,
  write_all_bufs = false,
  excluded_files = {},
}

-- Setup
M.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    M.config[k] = v
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_auto_save()", {})

  -- Auto-Save
  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("auto-save", { clear = true }),
    callback = function()
      vim.schedule(function()
        require("NeoSave").auto_save()
      end)
    end
  })
end

-- Toggle-Auto-Save
function M.toggle_auto_save()
  M.config.enabled = not M.config.enabled
  M.notify_NeoSave()
end

-- Excluded-Buf
function M.excluded_bufs()
  local excluded_files = M.config.excluded_files
  local current_file = fn.expand("%:p")
  return vim.tbl_contains(excluded_files, current_file)
end

-- Valid-Dir
function M.valid_directory()
  local filepath = fn.expand("%:p:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
end

-- Notify-NeoSave
function M.notify_NeoSave()
  vim.notify("NeoSave " .. (M.config.enabled and "Enabled" or "Disabled"))
end

-- Auto-Save
function M.auto_save()
  if not M.config.enabled or M.excluded_bufs() or not M.valid_directory() or not vim.bo.modifiable then
    return
  end

  local save_command = M.config.write_all_bufs and "silent! wall" or "silent! w"

  if vim.bo.modified and fn.bufname("%") ~= "" and not timer:is_active() then
    timer:start(135, 0, vim.schedule_wrap(function()
      cmd(save_command)
    end))
  end
end

return M
