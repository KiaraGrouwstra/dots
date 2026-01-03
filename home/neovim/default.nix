{
  pkgs,
  ...
}:
{
  config = {
    programs.neovim = {
      enable = true;
      # Add LSP servers
      extraPackages = with pkgs; [
        nil # Nix LSP
        rust-analyzer # Rust LSP
        lua-language-server # Lua LSP
      ];

      # Just load init.lua - it will require() everything else
      extraLuaConfig = builtins.readFile ./nvim/init.lua;

      plugins = with pkgs.vimPlugins; [
        kanagawa-paper-nvim
        nvim-treesitter.withAllGrammars
        mini-nvim
        nvim-cmp
        fzf-lua
        render-markdown-nvim # avante
        avante-nvim
        # {
        #   plugin = avante-nvim;
        #   type = "lua";
        #   config = builtins.readFile ./plugins/avante.lua;
        # }
      ];
    };

    # Symlink contents of nvim/ directory to ~/.config/nvim/
    xdg.configFile = {
      "nvim/lua" = {
        source = ./nvim/lua;
        recursive = true;
      };
      "nvim/ftplugin" = {
        source = ./nvim/ftplugin;
        recursive = true;
      };
    };
  };
}
