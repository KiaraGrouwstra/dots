{
  pkgs,
  user,
  ...
}:
{
  home-manager.users.${user} = {
    imports = [
      ./dotfiles.nix
      ./git.nix
      ./helix.nix
      ./lazygit.nix
      ./nushell.nix
      ./wezterm.nix
    ];
    home = {
      stateVersion = "24.11";
      sessionVariables = {
        EDITOR = "hx";
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        xdg-desktop-portal-cosmic
      ];
      config.common.default = [ "*" ];
      configPackages = [ pkgs.niri ];
    };
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
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
  };
}
