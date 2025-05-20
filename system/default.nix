{
  config,
  lib,
  pkgs,
  utils,
  ...
}@args:
let
  user = "kiara";
  lib' = import ../lib { inherit lib; };
  sources = import ../npins;
  pins = lib.mapAttrs (
    _: path:
    lib'.readTree {
      inherit path args;
      addMarkers = false;
    }
  ) sources;
  NIX_PATH =
    let
      entries = lib.mapAttrsToList (k: v: k + "=" + v) sources;
    in
    "${lib.concatStringsSep ":" entries}:flake";
  specialArgs = { inherit sources pins lib' user; };
in
{
  imports = with pins; [
    nixos-facter-modules.modules.nixos.facter
    home-manager.nixos
    vars.options
    vars.backends.on-machine
    <disko/module.nix>
    ./disks.nix
    ./user.nix
    ./vars.nix
    ./nix.nix
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
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Amsterdam";
  hardware.amdgpu.opencl.enable = true;

  # wheel
  security = {
    doas = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
        keepEnv = true;
        noPass = true;
      }];
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
    desktopManager = { cosmic.enable = true; };
  };
}
