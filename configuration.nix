{ config, ... }:
let
  pkgs = import <nixpkgs> {};
  user = "kiara";
in
{
  imports = [
    <nixos-facter-modules/modules/nixos/facter.nix>
    <disko/module.nix>
    <home-manager/nixos>
    ./disks.nix
    ./pinning.nix
  ];
  nix.package = pkgs.lix;
  system.stateVersion = "24.11";
  hardware.bluetooth.enable = true;
  nix.settings.experimental-features = "nix-command flakes";
  facter.reportPath = ./facter.json;
  boot.loader.systemd-boot.enable = true;
  security.sudo.wheelNeedsPassword = false;
  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = with pkgs; [
      npins
      git
      helix
      lazygit
      bat
      fd
      ripgrep
      keepassxc
      signal-desktop-bin
      nextcloud-client
      wezterm
      bluetuith
      vlc
      wl-clipboard
      tree
      jaq
      moreutils
    ];
  };
  programs = {
    direnv.enable = true;
  };
  services = {
    lorri.enable = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = user;
      cosmic-greeter.enable = true;
    };
    desktopManager = {
      cosmic.enable = true;
    };
  };
  home-manager.users.${user} = {
    home = {
      stateVersion = "24.11";
      sessionVariables = {
        EDITOR = "hx";
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
      config.common.default = [ "*" ];
    };
    programs = {
      librewolf = {
        enable = true;
        package = pkgs.librewolf-bin;
        nativeMessagingHosts = [ pkgs.keepassxc];
      };
      # does this even work?
      oh-my-posh = {
        enable = true;
        enableNushellIntegration = true;
        useTheme = "catppuccin";
      };
    };
  };
}
