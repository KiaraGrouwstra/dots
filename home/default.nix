{
  config,
  pkgs,
  user,
  ...
}:
let
  sysConfig = config;
in
{
  _class = "nixos";

  home-manager.users.${user} =
    { config, ... }:
    let
      exo-desktop = (
        let
          command = "${pkgs.xfce.exo}/bin/exo-open";
        in
        pkgs.makeDesktopItem {
          type = "Application";
          name = "exo-open";
          desktopName = "Exo-Open";
          mimeTypes = [
            "application/x-desktop"
          ];
          tryExec = command;
          exec = command;
        }
      );
    in
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
      ];
      home.stateVersion = "24.11";
      home.packages = [ exo-desktop ];
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      xdg.systemDirs.data = [
        "/run/current-system/sw/share"
        "/etc/profiles/per-user/${user}/share"
        "/home/${user}/.nix-profile/share"
        "/home/${user}/.local/share"
        "${sysConfig.services.displayManager.sessionData.desktops}/share"
      ];
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
          exo-desktop
        ];
        defaultApplications = {
          "application/x-desktop" = [
            "exo-open.desktop"
          ];
        };
      };
      programs = {
        bat = {
          enable = true;
          config = {
            style = "plain";
            paging = "never";
          };
        };
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
