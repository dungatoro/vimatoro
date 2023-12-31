# Vimatoro
This is my literate neovim config written in markdown. The following code blocks
are tangled with my `init.lua` using [urynus](https://github.com/dungatoro/urynus).

## Initial
Set the `<leader>` key to space. Many plugins will expect a leader key to be set
and refer to it in their default keybinds.

```lua init.lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
```

## Plugin Management

### Bootstrap Lazy.nvim

```lua init.lua
-- Install `lazy.nvim` plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)
```

 ### Installs
Plugins are installed here, some are installed with configuration
```lua init.lua
require('lazy').setup({
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  {'williamboman/mason.nvim'},
  {'williamboman/mason-lspconfig.nvim'},
  {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
  {'neovim/nvim-lspconfig'},
  {'hrsh7th/cmp-nvim-lsp'},
  {'hrsh7th/nvim-cmp'},
  {'L3MON4D3/LuaSnip'},

  {
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
      },
      build = ':TSUpdate',
    },
  
  {
    'navarasu/onedark.nvim',
    priority = 1000,
  },

  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'onedark',
        component_separators = '|',
        section_separators = '',
      }
    }
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },


  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end
      }
    }
  },

  'nvim-tree/nvim-web-devicons',
  'stevearc/oil.nvim',

  -- gc to comment highlighted text
  'numToStr/Comment.nvim',

  'mg979/vim-visual-multi',
})
```

## Theme
I use the onedark colour scheme from Atom. I've left a few of the settings here
in case I want to change the highlighting of specific elements; however these are
pretty default.
```lua init.lua
require('onedark').setup {
  style = 'darker', -- dark darker cool deep warm warmer light

  -- You can configure multiple style with comma separated,
  -- For e.g., keywords = 'italic,bold'
  code_style = {
    comments = 'italic',
    keywords = 'none',
    functions = 'none',
    strings = 'none',
    variables = 'none'
  },

  lualine = {
    transparent = false, -- lualine center bar transparency
  },

  colors = {},     -- Override default colors
  highlights = {}, -- Override highlight groups

  diagnostics = {
    darker = true,     -- darker colors for diagnostic
    undercurl = true,  -- use undercurl instead of underline for diagnostics
    background = true, -- use background color for virtual text
  },
}
require('onedark').load()
```

## Settings
My core editor settings are here. 

```lua init.lua
vim.o.termguicolors = true -- full colours

vim.wo.number = true
vim.o.colorcolumn = "81"
vim.o.signcolumn = "number"
vim.o.breakindent = true
vim.o.wrap = false
vim.o.scrolloff = 8

-- tabs
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'
```

### Undos
For better management of undo history I just use an undofile (I find the swap file
annoying and unnecessary).
```lua init.lua
vim.o.undofile = true
vim.o.swapfile = false
```

## Remaps
These remaps let me move highlited text.
```lua init.lua
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
```
This remap lets me copy text to the system clipboard.
```lua init.lua
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
```

## Telescope
[Telescope](https://github.com/nvim-telescope/telescope.nvim) is a powerful fuzzy
finder.
```lua init.lua
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      }
    }
  }
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')
```

I have some keybinds set up to do live grepping over my current git project.
```lua init.lua
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
  { desc = '[?] Find recently opened files' })
```

This does a search over the current neovim buffer. 
```lua init.lua
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
```

## Treesitter
I use [treesitter](https://github.com/nvim-treesitter/nvim-treesitter) primarily 
to provide better syntax highlighting. It provides other functionality; however 
I do not add any keybinds that make use of it.

```lua init.lua
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    highlight = { enable = true },
    indent = { enable = true },
  }
end, 0)
```

## LSP
The [Lsp](https://neovim.io/doc/user/lsp.html) is common in IDE's and provides 
code completion, syntaz highlighting, error and warning markers, definitions and 
etc.

### Setup LSP Zero

```lua init.lua
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  lsp_zero.default_keymaps({buffer = bufnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {},
  handlers = {
    lsp_zero.default_setup,
  },
})
```

### Completions

```lua init.lua
local cmp = require('cmp')

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end
    },
})
```

## Notetaking
This remap opens a markdown file with the title of the word underneath my cursor
in the current directory, if one already exists it will open that. This emulates 
[Obsidian](https://obsidian.md/)'s linked notes.

```lua init.lua
vim.keymap.set("n", "<leader>ne", [[:e <C-r><C-w>.md <CR>]])
```

## Oil
[Oil](https://github.com/stevearc/oil.nvim) is a handy file manager that allows 
me to edit a directory as if it was a vim buffer. I can also jump between files 
as you might expect from a normal file manager.

```lua init.lua
require("oil").setup({
  view_options = {
    show_hidden = true,
    is_hidden_file = function(name, bufnr)
      return vim.startswith(name, ".")
    end,
    is_always_hidden = function(name, bufnr)
      return false
    end,
    sort = {
      { "type", "asc" },
      { "name", "asc" },
    },
  },
})
```

This keybind opens up Oil in the current directory.
```lua init.lua
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
```
## Urynus
[Urynus](https://github.com/dungatoro/urynus) is a tool I wrote for literate
programming.

These keybinds make it faster to use in neovim.
```lua init.lua
vim.keymap.set("n", "<leader>ut", [[:!urynus tangle % <CR>]])
vim.keymap.set("n", "<leader>us", [[:!urynus snip % <C-r><C-w> <CR>]])
vim.keymap.set("n", "<leader>ui", [[:!urynus init]])
```

