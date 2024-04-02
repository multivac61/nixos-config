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
    interactiveShellInit = /* bash */ ''
      set -gx ATUIN_NOBIND "true"
      atuin init fish | source

      # bind to ctrl-p in normal and insert mode, add any other bindings you want here too
      bind \cp _atuin_search
      bind -M insert \cp _atuin_search
      bind \cr _atuin_search
      bind -M insert \cr _atuin_search

      starship init fish | source
      zoxide init fish | source
      direnv hook fish | source

      # eval (zellij setup --generate-auto-start fish | string collect)

      function fish_user_key_bindings
        fish_vi_key_bindings
      end

      set fish_vi_force_cursor
      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      block

      alias l="ls -altrh"

      # To back up previous home manager configurations
      set -Ux HOME_MANAGER_BACKUP_EXT ~/.nix-bak
    '';
    shellInit = /* bash */ '' 
    set fish_greeting # Disable greeting

    # name: 'Catppuccin mocha'
    # url: 'https://github.com/catppuccin/fish'
    # preferred_background: 1e1e2e

    set -g fish_color_normal cdd6f4
    set -g fish_color_command 89b4fa
    set -g fish_color_param f2cdcd
    set -g fish_color_keyword f38ba8
    set -g fish_color_quote a6e3a1
    set -g fish_color_redirection f5c2e7
    set -g fish_color_end fab387
    set -g fish_color_comment 7f849c
    set -g fish_color_error f38ba8
    set -g fish_color_gray 6c7086
    set -g fish_color_selection --background=313244
    set -g fish_color_search_match --background=313244
    set -g fish_color_option a6e3a1
    set -g fish_color_operator f5c2e7
    set -g fish_color_escape eba0ac
    set -g fish_color_autosuggestion 6c7086
    set -g fish_color_cancel f38ba8
    set -g fish_color_cwd f9e2af
    set -g fish_color_user 94e2d5
    set -g fish_color_host 89b4fa
    set -g fish_color_host_remote a6e3a1
    set -g fish_color_status f38ba8
    set -g fish_pager_color_progress 6c7086
    set -g fish_pager_color_prefix f5c2e7
    set -g fish_pager_color_completion cdd6f4
    set -g fish_pager_color_description 6c7086
    
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
    end
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

  yazi = {
    enable = true;
    enableFishIntegration = true;
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

      # neovim/nvim-lspconfig
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

      # Rust
      rust-analyzer
      rustfmt
      cargo
      graphviz

      ruff
      ruff-lsp

      # Svelte
      nodePackages.svelte-language-server
      nodePackages.typescript-language-server
      nodePackages.prettier
      nodePackages.eslint

      nodePackages.pyright
      nodePackages.vscode-json-languageserver-bin
      tailwindcss-language-server
      vscode-langservers-extracted

      marksman
      shellcheck
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
          neotest
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
          telekasten-nvim
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
            { import = "lazyvim.plugins.extras.lang.typescript" },
            { import = "lazyvim.plugins.extras.coding.copilot" },
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

        -- disable swap files
        vim.opt.swapfile = false
        vim.cmd.colorscheme "catppuccin-mocha"

        -- Disable syntax highlighting for .fish files
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
          pattern = "/private/tmp/**/*.fish",
          callback = function()
            vim.opt_local.syntax = "OFF"
          end,
        })

        -- don't show tabs
        vim.cmd [[ set showtabline=0 ]]

        require('telekasten').setup({
          home = vim.fn.expand("~/zettelkasten"), -- Put the name of your notes directory here
        })
      '';
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
