if vim.g.loaded_neosave then
  return
end

require('NeoSave').setup()

vim.g.loaded_neosave = true
