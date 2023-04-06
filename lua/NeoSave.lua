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

local NEOSAVE_DIR = fn.stdpath('cache') .. "/NeoSave"
local DISABLED_FILES_FILE = NEOSAVE_DIR .. "/neosave_bufs.json"

-- Create NeoSave directory if it doesn't exist
fn.mkdir(NEOSAVE_DIR, "p")

local function load_NeoSave()
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

local disabled_files = load_NeoSave()

-- Setup
NeoSave.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_NeoSave()", {})

  -- Clear-DisabledFiles
  user_cmd("ClearNeoSave", "lua require('NeoSave').clear_NeoSave()", {})

  -- Auto-Save
  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("auto-save", { clear = true }),
    callback = function()
      vim.schedule(function()
        NeoSave.auto_Save()
      end)
    end
  })
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
function NeoSave.auto_Save()
  if disabled_files[fn.expand('%:p')] or not NeoSave.valid_Directory()
      or not NeoSave.valid_Buffer() then
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

-- Valid-Buffer
function NeoSave.valid_Buffer()
  local buftype = vim.bo.buftype
  local disabled = { "help", "prompt", "nofile", "terminal" }
  if not vim.tbl_contains(disabled, buftype) then return true end
end

-- Toggle-NeoSave
function NeoSave.toggle_NeoSave()
  local file_path = fn.expand('%:p')
  disabled_files[file_path] = not disabled_files[file_path]
  NeoSave.save_Bufs()
  NeoSave.notify_NeoSave()
end

-- Valid-Dir
function NeoSave.valid_Directory()
  local filepath = fn.expand("%:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
end

-- Save-Disabled-Files
function NeoSave.save_Bufs()
  local items = {}
  for k, v in pairs(disabled_files) do
    if v then
      table.insert(items, k)
    end
  end
  local json_data = vim.fn.json_encode(items)
  vim.fn.writefile({ json_data }, DISABLED_FILES_FILE)
end

-- Clear-NeoSave
function NeoSave.clear_NeoSave()
  -- Delete the disabled files file
  if fn.filereadable(DISABLED_FILES_FILE) == 1 then
    fn.delete(DISABLED_FILES_FILE)
  end

  NeoSave.notify_NeoSave(true)
end

return NeoSave
