{
  lib,
  pkgs,
  ...
}:
let
  user = "kiara";
  sources = import ../npins;
  NIX_PATH =
    let
      entries = lib.mapAttrsToList (k: v: k + "=" + v) sources;
    in
    "${lib.concatStringsSep ":" entries}:flake=${sources.nixpkgs}:flake";
  specialArgs = {
    inherit
      sources
      user
      ;
  };
in
{
  imports = with sources; [
    "${nixos-facter-modules}/modules/nixos/facter.nix"
    "${home-manager}/nixos"
    "${vars}/options.nix"
    "${vars}/backends/on-machine.nix"
    "${disko}/module.nix"
    ./disks.nix
    ./user.nix
    ./vars.nix
    ./nix.nix
    ./wireguard.nix
  ];
  _module.args = specialArgs;
  nix.nixPath = [ NIX_PATH ];
  home-manager = {
    extraSpecialArgs = specialArgs;
    users.${user}.home.sessionVariables = {
      inherit NIX_PATH;
    };
  };
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
  networking.networkmanager.enable = true;
  systemd.network.wait-online.enable = false;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";
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
      cosmic-greeter.enable = true;
    };
    desktopManager = {
      cosmic.enable = true;
    };
  };
}
