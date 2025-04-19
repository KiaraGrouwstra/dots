{ config, lib, pkgs, utils, ... }@args:
let
  pkgs = import <nixpkgs> {};
  user = "kiara";
  pins = let
    readTree = import ./readTree.nix {};
    sources = import ./npins;
    mapper = _: path: readTree { inherit path args; addMarkers = false; };
  in lib.mapAttrs mapper sources;
in
{
  _module.args = { inherit pins; };
  imports = with pins; [
    nixos-facter-modules.modules.nixos.facter
    <disko/module.nix>
    home-manager.nixos
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
    shell = config.home-manager.users.kiara.programs.nushell.package;
    packages = with pkgs; [
      npins
      bat
      fd
      ripgrep
      keepassxc
      signal-desktop-bin
      nextcloud-client
      bluetuith
      vlc
      wl-clipboard
      tree
      jaq
      moreutils
      nixd
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
    imports = [
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
      oh-my-posh = {
        enable = true;
        enableNushellIntegration = true;
        useTheme = "catppuccin";
      };
    };
  };
}
