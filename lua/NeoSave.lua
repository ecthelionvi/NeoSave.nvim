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
local timer = vim.loop.new_timer()
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local user_cmd = vim.api.nvim_create_user_command

-- Configuration
local config = {
  enabled = true,
  write_all_bufs = false,
  excluded_files = {},
}

local NEO_SAVE_FILE = vim.fn.stdpath('cache') .. "/neosave_enabled.json"

local function load_enabled_files()
  if vim.fn.filereadable(NEO_SAVE_FILE) == 1 then
    local file_content = table.concat(vim.fn.readfile(NEO_SAVE_FILE))
    if file_content == "" then
      return {}
    end
    local decoded_data = vim.fn.json_decode(file_content)
    return decoded_data or {}
  else
    return {}
  end
end

local enabled_files = load_enabled_files()

local function create_config_dir()
  local cache_dir = vim.fn.stdpath('cache')
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, 'p')
  end
end

local function save_enabled_files()
  create_config_dir()
  local json_data = vim.fn.json_encode(enabled_files)
  vim.fn.writefile({json_data}, NEO_SAVE_FILE)
end

-- Setup
NeoSave.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_auto_save()", {})

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

-- Toggle-Auto-Save
function NeoSave.toggle_auto_save()
  local current_file = fn.expand("%:p")
  enabled_files[current_file] = not enabled_files[current_file]
  save_enabled_files()
  NeoSave.notify_NeoSave()
end

-- Excluded-Buf
function NeoSave.excluded_bufs()
  local excluded_files = config.excluded_files
  local current_file = fn.expand("%:p")
  return vim.tbl_contains(excluded_files, current_file)
end

-- Valid-Dir
function NeoSave.valid_directory()
  local filepath = fn.expand("%:p:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
end

-- Notify-NeoSave
function NeoSave.notify_NeoSave()
  local current_file = fn.expand("%:p")
  vim.notify("NeoSave " .. (enabled_files[current_file] and "Enabled" or "Disabled"))
end

-- Auto-Save
function NeoSave.auto_save()
  local current_file = fn.expand("%:p")
  if not enabled_files[current_file] or NeoSave.excluded_bufs() or not NeoSave.valid_directory() or not vim.bo.modifiable then
    return
  end

  local save_command = config.write_all_bufs and "silent! wall" or "silent! w"

  if vim.bo.modified and fn.bufname("%") ~= "" and not timer:is_active() then
    timer:start(135, 0, vim.schedule_wrap(function()
            cmd(save_command)
    end))
  end
end

return NeoSave



return NeoSave
