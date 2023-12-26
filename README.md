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

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
  },

  'kosayoda/nvim-lightbulb', -- code actions

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
vim.o.signcolumn = "no"
vim.o.colorcolumn = "81"
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

 ### Setup and Binds

```lua init.lua
-- This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- We create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
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

 ### Mason
Mason is a kind of LSP manager, new servers can be installed through a menu using
`:Mason`.

```lua init.lua
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
local servers = {
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      diagnostics = { disable = { 'missing-fields' } },
    }
  },

}

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

 ### Completions 
I use nvim-cmp as a completion engine. 

We need to broadcast to the lsp that we have completion capabilities so that we 
can utilise completions.
```lua init.lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
```

Here we initiliase 'luasnip' for snippet completions.
```lua init.lua
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}
```

The setup includes basic keybindings for navigating completions.
```lua init.lua
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
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
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'path' },
  },
}
```

 ### Lightbulb
[Lightbulb](https://github.com/kosayoda/nvim-lightbulb) adds code actions to 
neovim using the lsp.

```lua init.lua
require("nvim-lightbulb").setup({
  autocmd = { enabled = true },
  number = {
      enabled = true,
      text = "*",
      hl = "LightBulbNumber",
  },
})
```

## Notetaking
This remap opens a markdown file with the title of the word underneath my cursor
in the current directory, if one already exists it will open that. This emulates 
[Obsidian](https://obsidian.md/)'s linked notes.

```lua init.lua
vim.keymap.set("n", "<leader>nn", [[:e <C-r><C-w>.md <CR>]])
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

