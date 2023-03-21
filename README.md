<h1 align="center">
NeoSave.nvim
</h1>

<p align="center">
  <a href="https://github.com/ecthelionvi/NeoSave/stargazers">
    <img
      alt="Stargazers"
      src="https://img.shields.io/github/stars/ecthelionvi/NeoSave?style=for-the-badge&logo=starship&color=fae3b0&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
  <a href="https://github.com/ecthelionvi/NeoSave/issues">
    <img
      alt="Issues"
      src="https://img.shields.io/github/issues/ecthelionvi/NeoSave?style=for-the-badge&logo=gitbook&color=ddb6f2&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
  <a href="https://github.com/ecthelionvi/NeoSave/contributors">
    <img
      alt="Repo Size"
      src="https://img.shields.io/github/repo-size/ecthelionvi/NeoSave?style=for-the-badge&logo=opensourceinitiative&color=abe9b3&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
</p>

![demo](link-to-gif)

## 📃 Introduction

A Neovim plugin that automatically saves your files as you work, ensuring your progress is always preserved. NeoSave can be configured to save only the current buffer or all open buffers. You can also exclude specific files from auto-saving and toggle the feature on and off as needed.

## ⚙️ Features

- Option to save all open buffers or only the current buffer.
- Automatically saves files when they are modified.
- Exclude specific files from auto-saving.
- Toggle auto-saving on and off.

## 🔄 Persistence

NeoSave remembers the enabled state of the auto-save feature. When you toggle auto-saving on or off, the plugin will maintain that state across sessions.

## 🎛️ Usage

To toggle NeoSave on and off, you can use the `ToggleNeoSave` command:

```vim
:ToggleNeoSave
```
This command will turn NeoSave on if it's currently off, and vice versa.

You can also create a keybinding to toggle NeoSave more conveniently:

```lua
vim.keymap.set("n", "<leader>s", "<cmd>ToggleNeoSave<cr>", { noremap = true, silent = true })
```

## 📦 Installation

1. Install via your favorite package manager.

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "ecthelionvi/NeoSave.nvim",
  opts = {}
},
```

- [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use "ecthelionvi/NeoSave.nvim"
```

- [vim-plug](https://github.com/junegunn/vim-plug)
```VimL
Plug "ecthelionvi/NeoSave.nvim"
```

2. Setup the plugin in your `init.lua`. This step is not needed with lazy.nvim if `opts` is set as above.

```lua
require("NeoSave").setup()
```

## 🔧 Configuration

You can pass your config table into the `setup()` function or `opts` if you use lazy.nvim.

The available options:

- `write_all_bufs` (boolean) : whether to save all open buffers or only the current buffer
  - `false` (default)
- `excluded_files` (table of strings) : specific files to exclude from auto-saving
  - `{}` (default)
  - Example: `{ "config.lua", "secrets.txt" }`
- `notify` (boolean) : whether to show a notification when toggling auto-saving
  - `true` (default)

### Default config

```Lua
local config = {
   write_all_bufs = false,
   excluded_files = {},
   notify = true,
}
```
