{
  config,
  lib,
  pkgs,
  utils,
  ...
}@args:
let
  user = "kiara";
  sources = import ./npins;
  pins =
    let
      readTree = import ./readTree.nix { };
    in
    lib.mapAttrs (
      _: path:
      readTree {
        inherit path args;
        addMarkers = false;
      }
    ) sources;
  NIX_PATH =
    let
      entries = lib.mapAttrsToList (k: v: k + "=" + v) (import ./npins);
    in
    "${lib.concatStringsSep ":" entries}:flake";
in
{
  _module.args = { inherit pins; };
  imports = with pins; [
    nixos-facter-modules.modules.nixos.facter
    <disko/module.nix>
    home-manager.nixos
    vars.options
    vars.backends.on-machine
    ./disks.nix
  ];
  vars.settings.on-machine.enable = true;
  nixpkgs = {
    flake.source = <nixpkgs>;
    config.allowUnfree = true;
  };
  nix.package = pkgs.lix;
  system.stateVersion = "24.11";
  hardware.bluetooth.enable = true;
  facter.reportPath = ./facter.json;
  boot.loader.systemd-boot.enable = true;
  security.sudo.wheelNeedsPassword = false;
  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";
  hardware.amdgpu.opencl.enable = true;
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = config.home-manager.users.kiara.programs.nushell.package;
    packages = with pkgs; [
      bat
      bluetuith
      bun
      fd
      jaq
      keepassxc
      mattermost-desktop
      moreutils
      nextcloud-client
      nixd
      nixfmt-rfc-style
      npins
      ripgrep
      signal-desktop-bin
      stremio
      tree
      vlc
      wl-clipboard
      libreoffice-fresh
    ];
  };
  programs = {
    direnv.enable = true;
    steam.enable = true;
  };
  services = {
    lorri.enable = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = user;
      cosmic-greeter.enable = true;
    };
    desktopManager = { cosmic.enable = true; };
  };
  nix = {
    settings.experimental-features = "nix-command flakes";
    nixPath = [ NIX_PATH ];
  };
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
        inherit NIX_PATH;
        EDITOR = "hx";
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals =
        [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
      config.common.default = [ "*" ];
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
      yazi.enable = true;
      chromium.enable = true;
    };
  };
}
