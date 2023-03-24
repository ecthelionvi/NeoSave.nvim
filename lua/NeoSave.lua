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
    if file_content ~= "" then
      local decoded_data = vim.fn.json_decode(file_content)
      if not vim.tbl_isempty(decoded_data) then
        return decoded_data
      end
    end
  end
  return {}
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
  local json_data = vim.fn.json_encode(disabled_files)
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

-- Toggle-Auto-Save
function NeoSave.toggle_auto_save()
  local file_path = fn.expand('%:p')
  disabled_files[file_path] = not disabled_files[file_path]
  save_disabled_files()
  NeoSave.notify_NeoSave()
end

-- Valid-Dir
function NeoSave.valid_directory()
  local filepath = fn.expand("%:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
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
  if not NeoSave.valid_directory() or not vim.bo.modifiable or not vim.bo.buftype == "" then
    return
  end

  if not disabled_files[current_file] and vim.bo.modified and fn.expand("%") ~= "" and not timer:is_active() then
    timer:start(135, 0, vim.schedule_wrap(function()
      if config.write_all_bufs then
        cmd("silent! wall")
      else
        cmd("silent! w")
      end
    end))
  end
end

return NeoSave
