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
    "${lib.concatStringsSep ":" entries}:nixos-config=/home/${user}/nixos/configuration.nix:flake=${pkgs.path}:flake";
  specialArgs = {
    inherit
      sources
      system
      user
      ;
    sysConfig = config;
  };
  inherit (import sources.flake-inputs) import-flake;
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
  ];
  _module.args = specialArgs;
  nix.nixPath = [ NIX_PATH ];
  nix.channel.enable = false;
  home-manager = {
    extraSpecialArgs = specialArgs;
    users.${user}.home.sessionVariables = {
      inherit system NIX_PATH;
      BROWSER = "firefox";
      XDG_CURRENT_DESKTOP = "X-Generic";
    };
  };
  vars.settings.on-machine.enable = true;
  nixpkgs = {
    flake.source = pkgs.path;
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
  nix.package =
    (import-flake {
      src = sources.nix-src;
      overrides = {
        inherit (sources) nixpkgs;
        nixpkgs-regression = null;
        nixpkgs-23-11 = null;
        flake-parts = null;
        git-hooks-nix = null;
      };
    }).self.outputs.packages.${system}.nix-cli;
  system.stateVersion = "25.11";
  hardware.bluetooth.enable = true;
  facter.reportPath = ./facter.json;
  boot.loader.systemd-boot.enable = true;
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
  };
}
