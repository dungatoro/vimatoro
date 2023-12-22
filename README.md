# Vimatoro

My literate neovim config. I use [urynus](https://github.com/dungatoro/urynus)
to compile my config to lua.

## Leader Key
The first thing to set is the leader key, this is required by most plugins which
expect a `<leader>` that they can call in their default keybinds. My leader key
is set to space.

```lua init.lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
```

## Plugin Management
I use [lazy](https://github.com/folke/lazy.nvim) to manage plugins, mainly because
it is bootstrapped unlike [packer](https://github.com/wbthomason/packer.nvim), 
so there is no need to install an additional package.

### Bootstrap
```lua init.lua
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
Plugins are installed here, basic configuration can also be added here with the
plugin itself.
```lua init.lua
require('lazy').setup({
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
```

#### LSP Plugins
Lsp related plugins are bunched together as they all go hand in hand. I use 
[mason](https://github.com/williamboman/mason.nvim) to install plugins as and 
when
```lua init.lua
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
  },
```

I also make use of a completion engine and a few snippets...
```lua init.lua
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },
```

#### Visuals
Visual tweaks including the theme, status line and indent highlights are here.
I use the [onedark](https://github.com/navarasu/onedark.nvim) theme ripped from 
atom, and its [lualine](https://github.com/nvim-lualine/lualine.nvim) theme.

```lua init.lua
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
```

#### Treesitter
```lua init.lua
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },
```

#### Telescope
[Telescope](https://github.com/nvim-telescope/telescope.nvim) is a very powerful 
fuzzy finder that tends to integrate well with everything.

```lua init.lua
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
```

#### Misc
```lua init.lua
  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

}) -- DON'T FORGET: ends the install block
```

### Configuring Onedark
We can fine tune how different syntax elements are coloured with the onedark
palette.

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

### Core Settings

#### Visual Tweaks
```lua init.lua
vim.wo.number = true
vim.o.signcolumn = "no"
vim.o.colorcolumn = "81"
vim.o.breakindent = true
vim.o.wrap = false
vim.o.scrolloff = 8

vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.termguicolors = true
vim.o.completeopt = 'menuone,noselect'
```

#### Undofile
To save undo-history across sessions you need an undofile. I also disable 
swapfile because I find it too annoying.
```lua init.lua
vim.o.undofile = true
vim.o.swapfile = false
```

### Remaps

```lua init.lua
-- Basic Keymaps
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
```

### Telescope Config

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

#### Live grep
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

#### Fuzzy Finding
Basic fuzzy finding configuration is setup here.
```lua init.lua
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
```

### Treesitter
My treesitter configuration is pretty minimal. I do not make use of much outside
the smart indenting and better syntax highlighting
```lua init.lua
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    highlight = { enable = true },
    indent = { enable = true },
  }
end, 0)
```

### LSP Config

#### On Attach
The on_attach function runs when an LSP connects to a particular buffer. This 
can be customised for set functionality depending on the buffer.
```lua init.lua
local on_attach = function(_, bufnr)
  -- helper function for lsp mapping
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end
```

#### Keybinds
```init.lua
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end
```

#### Mason
We require mason to use as a lsp manager. Plugins can be installed from a menu
by running `:Mason`.
```lua init.lua
require('mason').setup()
require('mason-lspconfig').setup()
```


#### Per Server Config
We can set configuration for individual language server, for example, ignoring
certain warinings such as 'missing-fields' in lua.

```lua init.lua
local servers = {

  rust_analyzer = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      diagnostics = { disable = { 'missing-fields' } },
    }
  },
}
```


#### Require Handlers
This is mainly boilerplate to keep the lsp sane.
```lua init.lua
local mason_lspconfig = require 'mason-lspconfig'
mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
}
```

#### Completions
We broadcast completion capabilities to other plugins making use of the lsp
client, so that we can leverage completions wherever lsp is active.
```lua init.lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
```

Here we load up some basic settings...
```lua init.lua
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'path' },
  },
```

##### Completion Binds
```lua init.lua
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),

    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),

    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
}
```
