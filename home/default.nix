{
  pkgs,
  user,
  ...
}:
{
  _class = "nixos";

  home-manager.users.${user} = {
    _class = "homeManager";

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
