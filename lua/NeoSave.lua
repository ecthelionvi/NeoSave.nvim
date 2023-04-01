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
  enabled = true,
  save_views = true,
  write_all_bufs = false,
}

local DISABLED_FILES_FILE = vim.fn.stdpath('cache') .. "/neosave_disabled_files.json"
local VIEWS_FILE = vim.fn.stdpath('cache') .. "/neosave_views.json"

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

local function load_saved_views()
  if vim.fn.filereadable(VIEWS_FILE) == 1 then
    local file_content = table.concat(vim.fn.readfile(VIEWS_FILE))
    local decoded_data = vim.fn.json_decode(file_content)
    local views = {}
    if decoded_data ~= nil then
      for file_path, view in pairs(decoded_data) do
        views[file_path] = view
      end
    end
    return views
  else
    return {}
  end
end

local saved_views = load_saved_views()

-- Setup
NeoSave.setup = function(user_settings)
  -- Merge user settings with default settings
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  -- Return early if the plugin is disabled
  if config.enabled == false then
    return
  end

  -- Toggle-NeoSave
  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_NeoSave()", {})

  -- Clear-NeoSave
  user_cmd("ClearNeoSave", "lua require('NeoSave').clear_all()", {})

  -- Auto-Save
  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("auto-save", { clear = true }),
    callback = function()
      vim.schedule(function()
        NeoSave.auto_save()
      end)
    end
  })

  if config.save_views then
    autocmd({ "BufLeave", "BufWinLeave" }, {
      group = augroup("auto-save-view", { clear = true }),
      callback = function()
        vim.schedule(function()
          NeoSave.save_view()
        end)
      end
    })

    autocmd({ "BufEnter", "BufWinEnter" }, {
      group = "auto-save-view",
      callback = function()
        vim.schedule(function()
          NeoSave.load_view()
        end)
      end
    })
  end
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
function NeoSave.notify_NeoSave()
  vim.notify("NeoSave " .. (disabled_files[fn.expand('%:p')] and "Disabled" or "Enabled"))

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
end

-- Clear-Saved-Views
function NeoSave.clear_saved_views()
  saved_views = {}
  NeoSave.save_view()
end

-- Save-View
function NeoSave.save_view()
  if disabled_files[fn.expand('%:p')] or not NeoSave.valid_directory() or not vim.bo.modifiable or not vim.bo.buftype == "" then
    return
  end

  local view = vim.fn.winsaveview()
  saved_views[fn.expand('%:p')] = view

  local cache_dir = vim.fn.stdpath('cache')
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, 'p')
  end

  local json_data = vim.fn.json_encode(saved_views)
  vim.fn.writefile({ json_data }, VIEWS_FILE)
end

-- Load-View
function NeoSave.load_view()
  local file_path = fn.expand('%:p')
  local view = saved_views[file_path]
  if view ~= nil then
    vim.fn.winrestview(view)
  end
end

-- Clear-All
function NeoSave.clear_all()
  NeoSave.clear_disabled_files()
  NeoSave.clear_saved_views()
end

return NeoSave
