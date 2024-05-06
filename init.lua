-- Set leader to <Space>
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better undo history
vim.opt.backup = false 
vim.opt.swapfile = false
vim.opt.undofile = true 

-- Fix tabs
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true

-- Basic editor settings
vim.opt.number = true
vim.opt.wrap = false
vim.opt.scrolloff = 8

-- Move highlighted text
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Load [lazy.nvim](https://github.com/folke/lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", 
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Install packages
require("lazy").setup({
    -- Theme
    'navarasu/onedark.nvim',

    -- LSP base
    {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
    'neovim/nvim-lspconfig',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/nvim-cmp',
    'L3MON4D3/LuaSnip',

	-- LSP management
	'williamboman/mason.nvim',
	'williamboman/mason-lspconfig.nvim',
	'neovim/nvim-lspconfig',

	-- Code actions
	"aznhe21/actions-preview.nvim",

	-- Telescope (mainly for UI)
	'nvim-lua/plenary.nvim',
	'nvim-telescope/telescope.nvim',

	-- Treesitter syntax parser
	'nvim-treesitter/nvim-treesitter',

	-- Edit files in a vim buffer
	'stevearc/oil.nvim',
})

-- Set theme
require('onedark').setup { style = 'darker' }
require('onedark').load()

-- Start LSP Zero
local lsp_zero = require('lsp-zero')
lsp_zero.on_attach(function(client, bufnr)
    -- `:help lsp-zero-keybindings` for the available actions
    lsp_zero.default_keymaps({buffer = bufnr})
end)

-- Start Mason
require('mason').setup({})
require('mason-lspconfig').setup({
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({})
    end,
  },
})

-- Start and set bind `*` for code actions
require("actions-preview").setup()
vim.keymap.set({ "v", "n" }, "*", require("actions-preview").code_actions)

-- Start and set bind `-` for file management
require("oil").setup({
	view_options = {
		show_hidden = true,
	}
})
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- List scripts in telescope UI
function list_shell_scripts()
    require('telescope.builtin').find_files({
        prompt_title = 'Scripts',
        cwd = '~/.config/nvim/scripts',
        layout_strategy = 'horizontal',
        layout_config = {
            width = 0.6,
            height = 0.6,
        },
        attach_mappings = function(_, map)
            -- Execute selected script with <Enter>
            map('i', '<CR>', function(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry(prompt_bufnr)
                require('telescope.actions').close(prompt_bufnr)
                exec_shell_script(selection)
            end)
            return true
        end,
    })
end

-- Function to execute scripts
function exec_shell_script(selection)
    if selection then
        local script_path = selection.path
        vim.fn.jobstart(script_path, {
            on_exit = function(_, _, _)
                print('Script executed successfully')
            end,
            on_stderr = function(_, data, _)
                print('Error:', data)
            end,
        })
    end
end

-- Key Mapping to List Scripts
vim.api.nvim_set_keymap('n', '<leader>p', ':lua list_shell_scripts()<CR>', { noremap = true, silent = true })
