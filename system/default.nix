{
  lib,
  config,
  pkgs,
  ...
}:
let
  user = "kiara";
  sources = import ../npins;
  inherit (pkgs) system;
  NIX_PATH =
    let
      entries = lib.mapAttrsToList (k: v: k + "=" + v) sources;
    in
    "${lib.concatStringsSep ":" entries}:nixos-config=/etc/nixos/configuration.nix";
  specialArgs = {
    inherit
      sources
      system
      user
      ;
    sysConfig = config;
  };
in
{
  imports = with sources; [
    "${nixos-facter-modules}/modules/nixos/facter.nix"
    "${home-manager}/nixos"
    "${vars}/options.nix"
    "${vars}/backends/on-machine.nix"
    "${disko}/module.nix"
    "${noctalia-shell}/nix/nixos-module.nix"
    ./disks.nix
    ./greetd.nix
    ./user.nix
    ./vars.nix
    ./nix.nix
    ./wireguard.nix
    ./niri
    ./tts.nix
  ];
  _module.args = specialArgs;
  nix.nixPath = [ NIX_PATH ];
  nix.registry = lib.mapAttrs (_: path: {
    to = {
      type = "path";
      inherit path;
    };
  }) sources;
  nix.channel.enable = false;
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = specialArgs;
    users.${user}.home.sessionVariables = {
      inherit system NIX_PATH;
      BROWSER = "firefox";
      XDG_CURRENT_DESKTOP = "X-Generic";
    };
  };
  vars.settings.on-machine.enable = true;
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (
        final: prev:
        lib.mapAttrs (name: command: pkgs.writeShellScriptBin name "${command} $@") {
          xterm-256color = "xdg-terminal-exec";
          x-terminal-emulator = "xdg-terminal-exec";
          x-www-browser = "$BROWSER";
        }
        //
          lib.mapAttrs
            (
              k: overrides:
              prev.${k}.overrideAttrs (
                oldAttrs:
                {
                  src = sources.${k};
                }
                // (overrides k oldAttrs)
              )
            )
            {
              # lazyjj = _: _: { };
            }
      )
    ];
  };
  system.stateVersion = "25.11";
  hardware.bluetooth.enable = true;
  facter.reportPath = ./facter.json;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.systemd-boot.enable = true;
  boot.initrd.systemd.enable = true;
  networking.nameservers = [
    # dns.sb
    "185.222.222.222"
    "45.11.45.11"
  ];
  networking.networkmanager.enable = true;
  systemd.network.wait-online.enable = false;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";
  fonts.enableDefaultPackages = true;
  hardware.amdgpu.opencl.enable = true;

  # wheel
  security = {
    doas = {
      enable = true;
      extraRules = [
        {
          groups = [ "wheel" ];
          keepEnv = true;
          noPass = true;
        }
      ];
    };
    sudo = {
      enable = false;
      execWheelOnly = true;
    };
  };

  programs = {
    direnv.enable = true;
    steam.enable = true;
  };
  services = {
    userborn.enable = true;
    lorri.enable = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = user;
    };
    noctalia-shell = {
      enable = true;
      package = pkgs.callPackage "${sources.noctalia-shell}/nix/package.nix" { };
    };
    power-profiles-daemon.enable = true;
    upower.enable = true;
    flatpak.enable = true;
  };
}
