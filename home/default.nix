{
  pkgs,
  user,
  ...
}:
{
  _class = "nixos";

  home-manager.users.${user} =
    { config, ... }:
    {
      _class = "homeManager";

      imports = [
        ./dotfiles.nix
        ./git.nix
        ./helix.nix
        ./lazygit.nix
        ./nushell.nix
        ./style.nix
        ./wezterm.nix
        ./neovim
      ];
      home.stateVersion = "24.11";
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      xdg.mimeApps = {
        enable = true;
        defaultApplicationPackages = [
          pkgs.zathura
          config.programs.firefox.package
          pkgs.yazi
          pkgs.xfce.thunar
          config.programs.helix.package
          config.programs.neovim.package
          pkgs.libreoffice
          pkgs.vlc
        ];
      };
      programs = {
        firefox = {
          enable = true;
          nativeMessagingHosts = [ pkgs.keepassxc ];
        };
        oh-my-posh = {
          enable = true;
          enableNushellIntegration = true;
          useTheme = "catppuccin";
        };
        tealdeer.enable = true;
        pay-respects = {
          enable = true;
          enableNushellIntegration = true;
        };
        yazi.enable = true;
        chromium.enable = true;
      };
      services.kdeconnect.enable = true;
    };

  networking.firewall = rec {
    # KDE Connect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
