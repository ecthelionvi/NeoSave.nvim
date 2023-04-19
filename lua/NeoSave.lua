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
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local user_cmd = vim.api.nvim_create_user_command

local config = {
  write_all_bufs = false,
}

local NEOSAVE_DIR = fn.stdpath('cache') .. "/NeoSave"
local DISABLED_FILES_FILE = NEOSAVE_DIR .. "/neosave_bufs.json"

fn.mkdir(NEOSAVE_DIR, "p")

local function load_neosave()
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

local disabled_files = load_neosave()

NeoSave.setup = function(user_settings)
  if vim.g.neosave_setup then
    return
  end

  vim.g.neosave_setup = true

  user_settings = user_settings or {}
  for k, v in pairs(user_settings) do
    config[k] = v
  end

  autocmd({ "InsertLeave", "TextChanged" }, {
    group = augroup("auto-save", { clear = true }),
    callback = function()
      NeoSave.auto_save()
    end
  })

  user_cmd("ClearNeoSave", "lua require('NeoSave').clear_neosave()", {})

  user_cmd("ToggleNeoSave", "lua require('NeoSave').toggle_neosave()", {})
end

function NeoSave.clear_neosave()
  if fn.filereadable(DISABLED_FILES_FILE) == 1 then
    fn.delete(DISABLED_FILES_FILE)
  end

  NeoSave.notify_neosave(true)
end

function NeoSave.save_bufs()
  local items = {}
  for k, v in pairs(disabled_files) do
    if v then
      table.insert(items, k)
    end
  end
  local json_data = vim.fn.json_encode(items)
  vim.fn.writefile({ json_data }, DISABLED_FILES_FILE)
end

function NeoSave.valid_directory()
  local filepath = fn.expand("%:h")
  return filepath ~= "" and fn.isdirectory(filepath) == 1
end

function NeoSave.toggle_neosave()
  local file_path = fn.expand('%:p')
  disabled_files[file_path] = not disabled_files[file_path]
  NeoSave.save_bufs()
  NeoSave.notify_neosave()
end

function NeoSave.valid_buffer()
  local buftype = vim.bo.buftype
  local disabled = { "help", "prompt", "nofile", "terminal" }
  if not vim.tbl_contains(disabled, buftype) then return true end
end

function NeoSave.auto_save()
  local timer = vim.loop.new_timer()
  if disabled_files[fn.expand('%:p')] or not NeoSave.valid_directory()
      or not NeoSave.valid_buffer() then
    return
  end

  if timer then
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
end

function NeoSave.notify_neosave(clear)
  local timer = vim.loop.new_timer()
  if clear then
    vim.notify("NeoSave Data Cleared")
  else
    vim.notify("NeoSave " .. (disabled_files[fn.expand('%:p')] and "Disabled" or "Enabled"))
  end

  if timer then
    timer:start(3000, 0, vim.schedule_wrap(function()
      vim.cmd("echo ''")

      timer:stop()
      timer:close()
    end))
  end
end

return NeoSave
