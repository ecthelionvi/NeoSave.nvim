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
local NeoSave = {}

local fn = vim.fn
local cmd = vim.cmd
local api = vim.api
local timer = vim.loop.new_timer()
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local user_cmd = vim.api.nvim_create_user_command

-- Configuration
local config = {
  write_all_bufs = false,
}

local DISABLED_FILES_FILE = vim.fn.stdpath('cache') .. "/neosave_disabled_files.json"

local function load_disabled_files()
  if vim.fn.filereadable(DISABLED_FILES_FILE) == 1 then
    local file_content = table.concat(vim.fn.readfile(DISABLED_FILES_FILE))
    local decoded_data = vim.fn.json_decode(file_content)
    local enabled = {}
    if decoded_data ~= nil then
      for _, filename in ipairs(decoded_data) do
        enabled[filename] = true
      end
    end
    return enabled
  else
    return {}
  end
end

local disabled_files = load_disabled_files()

-- Setup
NeoSave.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_NeoSave()", {})

  -- Clear-DisabledFiles
  user_cmd("ClearNeoSave", "lua require('NeoSave').clear_disabled_files()", {})

  -- Auto-Save
  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("auto-save", { clear = true }),
    callback = function()
      vim.schedule(function()
        NeoSave.auto_save()
      end)
    end
  })
end

-- Toggle-NeoSave
function NeoSave.toggle_NeoSave()
  local file_path = fn.expand('%:p')
  disabled_files[file_path] = not disabled_files[file_path]
  NeoSave.save_disabled_files()
  NeoSave.notify_NeoSave()
end

-- Valid-Dir
function NeoSave.valid_directory()
  local filepath = fn.expand("%:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
end

-- Notify-NeoSave
function NeoSave.notify_NeoSave(clear)
  if clear then
    vim.notify("NeoSave Data Cleared")
  else
    vim.notify("NeoSave " .. (disabled_files[fn.expand('%:p')] and "Disabled" or "Enabled"))
  end

  -- Clear the message area after 3 seconds (3000 milliseconds)
  vim.defer_fn(function()
    api.nvim_echo({ { '' } }, false, {})
  end, 3000)
end

-- Auto-Save
function NeoSave.auto_save()
  if disabled_files[fn.expand('%:p')] or not NeoSave.valid_directory() or not vim.bo.modifiable or not vim.bo.buftype == "" then
    return
  end

  if vim.bo.modified and fn.expand("%") ~= "" and not timer:is_active() then
    timer:start(135, 0, vim.schedule_wrap(function()
      if config.write_all_bufs then
        cmd("silent! wall")
      else
        cmd("silent! w")
      end
    end))
  end
end

-- Save-Disabled-Files
function NeoSave.save_disabled_files()
  local cache_dir = vim.fn.stdpath('cache')
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, 'p')
  end

  local items = {}
  for k, v in pairs(disabled_files) do
    if v then
      table.insert(items, k)
    end
  end
  local json_data = vim.fn.json_encode(items)
  vim.fn.writefile({ json_data }, DISABLED_FILES_FILE)
end

-- Clear-Disabled-Files
function NeoSave.clear_disabled_files()
  disabled_files = {}
  NeoSave.save_disabled_files()
  NeoSave.notify_NeoSave(true)
end

return NeoSave
