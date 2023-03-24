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
  custom_NeoSave = {},
}

local DISABLED_FILES_FILE = vim.fn.stdpath('cache') .. "/neosave_disabled_files.json"

local function load_disabled_files()
  if vim.fn.filereadable(DISABLED_FILES_FILE) == 1 then
    local file_content = table.concat(vim.fn.readfile(DISABLED_FILES_FILE))
    local decoded_data = vim.fn.json_decode(file_content)
    local disabled = {}
    if decoded_data ~= nil then
      for _, filename in ipairs(decoded_data) do
        disabled[filename] = true
      end
    end
    return disabled
  else
    return {}
  end
end

local disabled_files = load_disabled_files()

local function create_config_dir()
  local cache_dir = vim.fn.stdpath('cache')
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, 'p')
  end
end

local function save_disabled_files()
  create_config_dir()
  local items = {}
  for k, v in pairs(disabled_files) do
    if v then
      table.insert(items, k)
    end
  end
  local json_data = vim.fn.json_encode(items)
  vim.fn.writefile({ json_data }, DISABLED_FILES_FILE)
end

-- Setup
NeoSave.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_auto_save()", {})

  -- Apply-NeoSave
  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("apply-auto-save", { clear = true }),
    callback = function()
      vim.schedule(function()
        NeoSave.apply_auto_save()
      end)
    end
  })
end

-- Toggle-Auto-Save
function NeoSave.toggle_auto_save()
  local current_file = fn.expand("%:p")
  disabled_files[current_file] = not disabled_files[current_file]
  save_disabled_files()
  NeoSave.notify_NeoSave()
end

-- Notify-NeoSave
function NeoSave.notify_NeoSave()
  local current_file = fn.expand("%:p")
  vim.notify("NeoSave " .. (disabled_files[current_file] and "Disabled" or "Enabled"))

  -- Clear the message area after 3 seconds (3000 milliseconds)
  vim.defer_fn(function()
    api.nvim_echo({ { '' } }, false, {})
  end, 3000)
end

-- Auto-Save
function NeoSave.auto_save()
  local current_file = fn.expand("%:p")
  if not NeoSave.valid_directory() or not vim.bo.modifiable or disabled_files[current_file] then
    return
  end

  local save_command = config.write_all_bufs and "silent! wall" or "silent! w"

  if vim.bo.modified and fn.expand("%") ~= "" and not timer:is_active() then
    timer:start(135, 0, vim.schedule_wrap(function()
      cmd(save_command)
    end))
  end
end

return NeoSave
