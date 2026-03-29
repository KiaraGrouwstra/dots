{ lib, pkgs, sources, ... }:
let
  lanzabootePackages = import "${sources.lanzaboote}/nix/packages/default.nix" {
    inherit pkgs;
    crane = import sources.crane { inherit pkgs; };
    rust-overlay = sources.rust-overlay;
  };
in
{
  # lanzaboote takes over signing; disable plain systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    package = lanzabootePackages.lzbt;
  };
}
