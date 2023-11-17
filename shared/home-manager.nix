{ config, pkgs, lib, ... }:

let
  name = "Ólafur Bjarki Bogason";
  user = "olafur";
  email = "olafur@genkiinstruments.com";
in
{
  # Shared shell configuration
  fish = {
    enable = true;
    plugins = [
      {
        name = "base16-fish";
        src = pkgs.fetchFromGitHub {
          owner = "tomyun";
          repo = "base16-fish";
          rev = "2f6dd973a9075dabccd26f1cded09508180bf5fe";
          sha256 = "PebymhVYbL8trDVVXxCvZgc0S5VxI7I1Hv4RMSquTpA=";
        };
      }
      {
        name = "hydro";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "hydro";
          rev = "a5877e9ef76b3e915c06143630bffc5ddeaba2a1";
          sha256 = "nJ8nQqaTWlISWXx5a0WeUA4+GL7Fe25658UIqKa389E=";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          owner = "franciscolourenco";
          repo = "done";
          rev = "37117c3d8ed6b820f6dc647418a274ebd1281832";
          sha256 = "cScH1NzsuQnDZq0XGiay6o073WSRIAsshkySRa/gJc0=";
        };
      }
    ];
    interactiveShellInit = ''
      atuin init fish | source
      starship init fish | source
      zoxide init fish | source
      direnv hook fish | source

      # eval (zellij setup --generate-auto-start fish | string collect)

      # I'm growing a neckbeard: Set the cursor shapes for the different vi modes.
      set fish_cursor_default block blink
      set fish_cursor_insert line blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual block

      function fish_user_key_bindings
          # Execute this once per mode that emacs bindings should be used in
          fish_default_key_bindings -M insert
          fish_vi_key_bindings --no-erase insert
      end
    '';
    shellInit = '' 
    set fish_greeting # Disable greeting

    # TokyoNight Color Palette
    set -l foreground c8d3f5
    set -l selection 2d3f76
    set -l comment 636da6
    set -l red ff757f
    set -l orange ff966c
    set -l yellow ffc777
    set -l green c3e88d
    set -l purple fca7ea
    set -l cyan 86e1fc
    set -l pink c099ff

    # Syntax Highlighting Colors
    set -g fish_color_normal $foreground
    set -g fish_color_command $cyan
    set -g fish_color_keyword $pink
    set -g fish_color_quote $yellow
    set -g fish_color_redirection $foreground
    set -g fish_color_end $orange
    set -g fish_color_error $red
    set -g fish_color_param $purple
    set -g fish_color_comment $comment
    set -g fish_color_selection --background=$selection
    set -g fish_color_search_match --background=$selection
    set -g fish_color_operator $green
    set -g fish_color_escape $pink
    set -g fish_color_autosuggestion $comment
    
    # https://github.com/d12frosted/environment/blob/78486b74756142524a4ccd913c85e3889a138e10/nix/home.nix#L117
    # prompt configurations
    set -g hydro_symbol_prompt "λ"
    if test "$TERM" = linux
      set -g hydro_symbol_prompt ">"
    end

    # done configurations
    set -g __done_notification_command 'notify send -t "$title" -m "$message"'
    set -g __done_enabled 1
    set -g __done_allow_nongraphical 1
    set -g __done_min_cmd_duration 8000

    # see https://github.com/LnL7/nix-darwin/issues/122
    set -ga PATH ${config.xdg.configHome}/bin
    set -ga PATH $HOME/.local/bin
    set -ga PATH /run/wrappers/bin
    set -ga PATH $HOME/.nix-profile/bin
    if test $KERNEL_NAME darwin
      set -ga PATH /opt/homebrew/opt/llvm/bin
      set -ga PATH /opt/homebrew/bin
      set -ga PATH /opt/homebrew/sbin
    end
    set -ga PATH /run/current-system/sw/bin
    set -ga PATH /nix/var/nix/profiles/default/bin

    # Adapt construct_path from the macOS /usr/libexec/path_helper executable for
    # fish usage;
    #
    # The main difference is that it allows to control how extra entries are
    # preserved: either at the beginning of the VAR list or at the end via first
    # argument MODE.
    #
    # Usage:
    #
    #   __fish_macos_set_env MODE VAR VAR-FILE VAR-DIR
    #
    #   MODE: either append or prepend
    #
    # Example:
    #
    #   __fish_macos_set_env prepend PATH /etc/paths '/etc/paths.d'
    #
    #   __fish_macos_set_env append MANPATH /etc/manpaths '/etc/manpaths.d'
    #
    # [1]: https://opensource.apple.com/source/shell_cmds/shell_cmds-203/path_helper/path_helper.c.auto.html .
    #
    function macos_set_env -d "set an environment variable like path_helper does (macOS only)"
      # noops on other operating systems
      if test $KERNEL_NAME darwin
        set -l result
        set -l entries

        # echo "1. $argv[2] = $$argv[2]"

        # Populate path according to config files
        for path_file in $argv[3] $argv[4]/*
          if [ -f $path_file ]
            while read -l entry
              if not contains -- $entry $result
                test -n "$entry"
                and set -a result $entry
              end
            end <$path_file
          end
        end

        # echo "2. $argv[2] = $result"

        # Merge in any existing path elements
        set entries $$argv[2]
        if test $argv[1] = "prepend"
          set entries[-1..1] $entries
        end
        for existing_entry in $entries
          if not contains -- $existing_entry $result
            if test $argv[1] = "prepend"
              set -p result $existing_entry
            else
              set -a result $existing_entry
            end
          end
        end

        # echo "3. $argv[2] = $result"

        set -xg $argv[2] $result
      end
    end
    macos_set_env prepend PATH /etc/paths '/etc/paths.d'


    set -ga MANPATH $HOME/.local/share/man
    set -ga MANPATH $HOME/.nix-profile/share/man
    if test $KERNEL_NAME darwin
      set -ga MANPATH /opt/homebrew/share/man
    end
    set -ga MANPATH /run/current-system/sw/share/man
    set -ga MANPATH /nix/var/nix/profiles/default/share/man
    macos_set_env append MANPATH /etc/manpaths '/etc/manpaths.d'

    set -gp NIX_PATH nixpkgs=$HOME/.nix-defexpr/channels_root/nixpkgs

    if test $KERNEL_NAME darwin
      set -gx HOMEBREW_PREFIX /opt/homebrew
      set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
      set -gx HOMEBREW_REPOSITORY /opt/homebrew
      set -gp INFOPATH /opt/homebrew/share/info
      set -gx LDFLAGS "-L/opt/homebrew/opt/llvm/lib"
      set -gx CPPFLAGS "-I/opt/homebrew/opt/llvm/include"
    end

    # Completion Pager Colors
    set -g fish_pager_color_progress $comment
    set -g fish_pager_color_prefix $cyan
    set -g fish_pager_color_completion $foreground
    set -g fish_pager_color_description $comment
    set -g fish_pager_color_selected_background --background=$selection

    set -x PNPM_HOME /Users/olafur/Library/pnpm
    set -Ua PATH $PNPM_HOME

    set -x NOTION_TOKEN secret_Yc7GzmUIFdqBHEEMYSBTdj3Rs9emdVKGVNVkuzLjyZG
    set -x OPENAI_API_KEY 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

    set -x DOCKER_HOST unix:///$HOME/.docker/run/docker.sock

    # bun
    set -x BUN_INSTALL "$HOME/.bun"
    set -Ua PATH $BUN_INSTALL/bin

    # NIX
    set -Ua PATH /nix/var/nix/profiles/default/bin

    set -Ua PATH $HOME/bin /usr/local/bin / /Applications/ARM/bin /nix/var/nix/profiles/default/bin
  '';
  };

  git = {
    enable = true;
    ignores = [ "*.swp" ];
    userName = name;
    userEmail = email;
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # LazyVim
      lua-language-server
      stylua

      # Telescope
      ripgrep

      # neovim/nvim-lspconfig
      # Nix
      nil
      nixpkgs-fmt

      # C
      clang-tools

      # Rust
      rust-analyzer
      rustfmt
      cargo
      graphviz

      # Svelte
      nodePackages.svelte-language-server
      nodePackages.typescript-language-server
      nodePackages.prettier
      nodePackages.eslint

      nodePackages.pyright
      nodePackages.vscode-json-languageserver-bin
      ruff
      tailwindcss-language-server
      vscode-langservers-extracted

      marksman
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    extraLuaConfig =
      let
        plugins = with pkgs.vimPlugins; [
          rustaceanvim
          # LazyVim
          LazyVim
          bufferline-nvim
          cmp-buffer
          cmp-nvim-lsp
          cmp-path
          cmp_luasnip
          conform-nvim
          dashboard-nvim
          dressing-nvim
          flash-nvim
          friendly-snippets
          gitsigns-nvim
          indent-blankline-nvim
          clangd_extensions-nvim
          lualine-nvim
          neo-tree-nvim
          neoconf-nvim
          neodev-nvim
          noice-nvim
          nui-nvim
          nvim-cmp
          nvim-dap # Rust
          nvim-lint
          nvim-lspconfig
          nvim-notify
          nvim-spectre
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-ts-autotag
          nvim-ts-context-commentstring
          nvim-web-devicons
          persistence-nvim
          plenary-nvim
          telescope-fzf-native-nvim
          telescope-nvim
          todo-comments-nvim
          tokyonight-nvim
          trouble-nvim
          vim-illuminate
          vim-startuptime
          which-key-nvim
          { name = "LuaSnip"; path = luasnip; }
          { name = "mini.ai"; path = mini-nvim; }
          { name = "mini.bufremove"; path = mini-nvim; }
          { name = "mini.comment"; path = mini-nvim; }
          { name = "mini.indentscope"; path = mini-nvim; }
          { name = "mini.pairs"; path = mini-nvim; }
          { name = "mini.surround"; path = mini-nvim; }
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        require("lazy").setup({
          defaults = {
            lazy = true,
          },
          dev = {
            -- reuse files from pkgs.vimPlugins.*
            path = "${lazyPath}",
            patterns = { "." },
            -- fallback to download
            fallback = true,
          },
          spec = {
            -- add LazyVim and import its plugins
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- import any extras modules here
            { import = "lazyvim.plugins.extras.lang.typescript" },
            { import = "lazyvim.plugins.extras.coding.copilot" },
            { import = "lazyvim.plugins.extras.lang.json" },
            { import = "lazyvim.plugins.extras.lang.python" },
            { import = "lazyvim.plugins.extras.lang.markdown" },
            { import = "lazyvim.plugins.extras.linting.eslint" },
            { import = "lazyvim.plugins.extras.lang.clangd" },
            { import = "lazyvim.plugins.extras.formatting.prettier" },
            { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
            -- The following configs are needed for fixing lazyvim on nix
            -- force enable telescope-fzf-native.nvim
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            -- disable mason.nvim, use programs.neovim.extraPackages
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            -- import/override with your plugins
            { import = "plugins" },
            -- treesitter handled by xdg.configFile."nvim/parser", put this line at the end of spec to clear ensure_installed
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
          },
        })

        local function map(mode, lhs, rhs, opts)
            local keys = require("lazy.core.handler").handlers.keys
            ---@cast keys LazyKeysHandler
            -- do not create the keymap if a lazy keys handler exists
            if not keys.active[keys.parse({ lhs, mode = mode }).id] then
                opts = opts or {}
                opts.silent = opts.silent ~= false
                if opts.remap and not vim.g.vscode then
                    opts.remap = nil
                end
                vim.keymap.set(mode, lhs, rhs, opts)
            end
        end

        map({ "n", "i", "v" }, "<A-j>", "", { desc = "Move down" })
        map({ "n", "i", "v" }, "<A-k>", "", { desc = "Move up" })

        vim.g.rustaceanvim = {
          -- Plugin configuration
          tools = {
          },
          -- LSP configuration
          server = {
            on_attach = function(client, bufnr)
              -- you can also put keymaps in here
              lsp.on_attach(client, bufnr)
              lsp.on_dap_attach(bufnr)
            end,
            settings = {
              -- rust-analyzer language server configuration
              ["rust-analyzer"] = {
                  cargo = {
                      allFeatures = true,
                  },
                  checkOnSave = {
                      allFeatures = true,
                      command = "clippy",
                      extraArgs = { "--no-deps" },
                  },
                  procMacro = {
                      ignored = {
                          ["async-trait"] = { "async_trait" },
                          ["napi-derive"] = { "napi" },
                          ["async-recursion"] = { "async_recursion" },
                      },
                  },
              },
            },
          },
          -- DAP configuration
          dap = { },
        }

        -- https://github.com/neovim/nvim-lspconfig#suggested-configuration
        -- Global mappings.
        -- See `:help vim.diagnostic.*` for documentation on any of the below functions
        vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
        vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

        -- Use LspAttach autocommand to only map the following keys
        -- after the language server attaches to the current buffer
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            local opts = { buffer = ev.buf }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set('n', '<space>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<space>f', function()
              vim.lsp.buf.format { async = true }
            end, opts)
          end,
        })
      '';
  };

  alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        # opacity = 1.0;
        padding = {
          x = 0;
          y = 0;
        };
        option_as_alt = "Both";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 16)
        ];
      };

      dynamic_padding = true;
      decorations = "full";
      title = "Terminal";
      class = {
        instance = "Alacritty";
        general = "Alacritty";
      };

      # TokyoNight Moon
      colors = {
        primary = {
          background = "0x222436";
          foreground = "0xc8d3f5";
        };

        normal = {
          black = "0x1b1d2b";
          red = "0xff757f";
          green = "0xc3e88d";
          yellow = "0xffc777";
          blue = "0x82aaff";
          magenta = "0xc099ff";
          cyan = "0x86e1fc";
          white = "0x828bb8";
        };

        bright = {
          black = "0x444a73";
          red = "0xff757f";
          green = "0xc3e88d";
          yellow = "0xffc777";
          blue = "0x82aaff";
          magenta = "0xc099ff";
          cyan = "0x86e1fc";
          white = "0xc8d3f5";
        };
      };
    };
  };

  zellij = {
    enable = true;
    enableFishIntegration = true;
  };

  starship = {
    enable = true;
    enableFishIntegration = true;
  };

  ssh = {
    enable = true;

    extraConfig = lib.mkMerge [
      ''
        Host github.com
          Hostname github.com
          IdentitiesOnly yes
      ''
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        ''
          IdentityFile /home/${user}/.ssh/id_github
        '')
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        ''
          IdentityFile /Users/${user}/.ssh/id_github
        '')
    ];
  };
}
