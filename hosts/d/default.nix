{ lib, pkgs, user, email, ... }:

{
  imports = [
    ../../modules/shared
  ];

  # nix-darwin specific configuration, e.g., we don't want to hide the user
  users.users.${user} = {
    isHidden = false;
    home = "/Users/${user}";
    name = "${user}";
    shell = pkgs.fish;
  };

  homebrew = {
    enable = true;
    casks = [ "raycast" "arc" ];
    masApps = {
      # `nix run nixpkgs#mas -- search <app name>`
      "Keynote" = 409183694;
    };
  };

  # Since we're using fish as our shell
  programs.fish.enable = true;

  home-manager.users.${user} = { ... }:
    {
      home.enableNixpkgsReleaseCheck = false;
      home.stateVersion = "23.05";

      xdg.enable = true; # Needed for fish interactiveShellInit hack
      programs = {
        alacritty = {
          enable = true;
        };
        lazygit = {
          enable = true;
          settings.gui.skipDiscardChangeWarning = true;
        };
        atuin = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            exit_mode = "return-query";
            keymap_mode = "auto";
            prefers_reduced_motion = true;
            enter_accept = true;
            show_help = false;
            # TODO: Unfortunately not working ATM: https://forum.atuin.sh/t/help-with-macos-ctrl-n-key-shortcuts/271
            # ctrl_n_shortcuts = true;
          };
        };
        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };
        direnv = {
          enable = true;
          nix-direnv.enable = true; # Adds FishIntegration automatically
        };
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
          interactiveShellInit = /* bash */ ''
            # bind to ctrl-p in normal and insert mode, add any other bindings you want here too
            bind \cp _atuin_search
            bind -M insert \cp _atuin_search
            bind \cr _atuin_search
            bind -M insert \cr _atuin_search

            set -gx DIRENV_LOG_FORMAT ""

            function fish_user_key_bindings
              fish_vi_key_bindings
            end

            set fish_vi_force_cursor
            set fish_cursor_default     block      blink
            set fish_cursor_insert      line       blink
            set fish_cursor_replace_one underscore blink
            set fish_cursor_visual      block

            alias l="eza -l -g -a --sort=modified --git --icons"
            alias n="nvim"

            # To back up previous home manager configurations
            set -Ux HOME_MANAGER_BACKUP_EXT ~/.nix-bak
          '';

          shellInit = /* bash */ '' 
    set fish_greeting # Disable greeting
    fish_config theme choose "Catppuccin Mocha"
    
    # https://github.com/d12frosted/environment/blob/78486b74756142524a4ccd913c85e3889a138e10/nix/home.nix#L117 prompt configurations
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
    set -ga PATH $HOME/.local/bin
    set -ga PATH /run/wrappers/bin
    set -ga PATH $HOME/.nix-profile/bin
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

    if test $KERNEL_NAME darwin
      set -gx HOMEBREW_PREFIX /opt/homebrew
      set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
      set -gx HOMEBREW_REPOSITORY /opt/homebrew
      set -gp INFOPATH /opt/homebrew/share/info
    end
  '';
        };

        ssh.enable = true;

        git = {
          enable = true;
          ignores = [ "*.swp" ];
          userName = "${user}";
          userEmail = "${email}";
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
          defaultEditor = true;
          extraPackages = with pkgs; [
            # LazyVim
            lua-language-server
            stylua

            # Telescope
            ripgrep

            # workaround for nvim-spectre...
            (writeShellScriptBin "gsed" ''exec ${pkgs.gnused}/bin/sed "$@"'')

            # Nix
            nil
            nixpkgs-fmt

            # zig
            zig
            zls

            # C
            clang-tools
            neocmakelsp
            vscode-extensions.ms-vscode.cmake-tools

            # Svelte
            nodePackages.svelte-language-server
            nodePackages.typescript-language-server
            nodePackages.prettier
            nodePackages.eslint
            nodePackages.pyright
            nodePackages.vscode-json-languageserver-bin
            tailwindcss-language-server
            vscode-langservers-extracted

            nodePackages_latest.nodejs # needed for copilot

            # Other
            marksman
            shellcheck
            markdownlint-cli
          ];

          plugins = with pkgs.vimPlugins; [
            lazy-nvim
          ];

          extraLuaConfig =
            let
              plugins = with pkgs.vimPlugins; [
                # Rust
                nvim-dap
                crates-nvim
                rust-tools-nvim
                neotest-rust
                rustaceanvim

                copilot-lua
                copilot-cmp

                # Clojure
                conjure
                cmp-conjure

                # LazyVim
                LazyVim
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
                oil-nvim
                neoconf-nvim
                neodev-nvim
                noice-nvim
                nui-nvim
                calendar-vim
                nvim-cmp
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
                catppuccin-nvim
                trouble-nvim
                vim-illuminate
                vim-startuptime
                which-key-nvim
                harpoon2
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
              /* lua */ ''
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
                  { import = "lazyvim.plugins.extras.coding.copilot" },
                  { import = "lazyvim.plugins.extras.lang.typescript" },
                  { import = "lazyvim.plugins.extras.lang.json" },
                  { import = "lazyvim.plugins.extras.lang.python" },
                  { import = "lazyvim.plugins.extras.lang.markdown" },
                  { import = "lazyvim.plugins.extras.lang.rust" },
                  { import = "lazyvim.plugins.extras.linting.eslint" },
                  -- { import = "lazyvim.plugins.extras.lang.clangd" },
                  -- { import = "lazyvim.plugins.extras.lang.cmake" },
                  { import = "lazyvim.plugins.extras.formatting.prettier" },
                  { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
                  -- The following configs are needed for fixing lazyvim on nix
                  -- force enable telescope-fzf-native.nvim
                  { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
                  -- disable mason.nvim, use programs.neovim.extraPackages
                  { "williamboman/mason-lspconfig.nvim", enabled = false },
                  { "williamboman/mason.nvim", enabled = false },
                  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
                  { "akinsho/bufferline.nvim", enabled = false },
                  -- import/override with your plugins
                  { import = "plugins" },
                  -- treesitter handled by xdg.configFile."nvim/parser", put this line at the end of spec to clear ensure_installed
                  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
                },
              })

              -- Note: This is a workaround due to a bug I don't know where is, either in mini-comment of the kdl treesitter spec?
              vim.api.nvim_create_autocmd("FileType", {
                pattern = "kdl",
                callback = function()
                  vim.bo.commentstring = "//%s"
                end
              })

              -- Disable swap files
              vim.opt.swapfile = false

              -- Set colorscheme
              vim.cmd.colorscheme "catppuccin-mocha"

              -- Disable syntax highlighting for .fish files
              vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
                pattern = "*.fish",
                callback = function()
                  vim.cmd("syntax off")
                end,
              })

              -- Don't show tabs
              vim.cmd [[ set showtabline=0 ]]
            '';
        };

        zellij = {
          enable = true;
          enableFishIntegration = true;
        };

        starship = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            add_newline = false;
            command_timeout = 1000;
            scan_timeout = 3;
          };
        };
      };

      # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
      home.file.".config/nvim/parser".source =
        with pkgs;
        let
          parsers = symlinkJoin {
            name = "treesitter-parsers";
            paths = (vimPlugins.nvim-treesitter.withPlugins (p: with p; [
              bash
              c
              cpp
              cmake
              diff
              html
              javascript
              jsdoc
              json
              jsonc
              lua
              luadoc
              luap
              markdown
              markdown_inline
              python
              query
              regex
              toml
              tsx
              typescript
              vim
              vimdoc
              yaml
              nix
              rust
              ron
              kdl
              svelte
              sql
            ])).dependencies;
          };
        in
        "${parsers}/parser";
      home.file.".config/nvim" = { recursive = true; source = ../../modules/shared/config/nvim; };

      home.file.".config/alacritty/alacritty.toml".source = ../../modules/shared/config/alacritty.toml;
      home.file.".config/fish/themes/Catppuccin Mocha.theme".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/catppuccin/fish/main/themes/Catppuccin%20Mocha.theme";
        sha256 = "MlI9Bg4z6uGWnuKQcZoSxPEsat9vfi5O1NkeYFaEb2I=";
      };
      home.file.".config/karabiner/karabiner.json".source = ./karabiner.json;

      # NOTE: Use this to add packages available everywhere on your system
      home.packages = with pkgs; [
        neofetch
        wget
        zip
        moonlight-qt
        magic-wormhole-rs
        tldr
        bitwarden-cli
        gh
        btop
      ];
    };

  fonts = {
    ${if pkgs.stdenv.isDarwin then "fonts" else "packages"} = [
      (pkgs.nerdfonts.override {
        fonts = [ "JetBrainsMono" ];
      })
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  services.tailscale.enable = true;

  # Setup user, packages, programs
  nix = {
    settings.trusted-users = [ "@admin" "${user}" ];

    gc = {
      user = "root";
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Enable fonts dir
  fonts.fontDir.enable = true;

  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 72;
        orientation = "left";
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    activationScripts.postActivation.text = ''
      # Set the default shell as fish for the user
      sudo chsh -s ${lib.getBin pkgs.fish}/bin/fish "${user}"
      
      # normal minimum is 15 (225 ms)\ defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
      defaults write -g InitialKeyRepeat -int 10 
      defaults write -g KeyRepeat -int 1
    '';
  };
}
