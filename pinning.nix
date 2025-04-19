{ lib, ... }:
{
  nixpkgs.flake.source = <nixpkgs>;
  nix = {
    settings.experimental-features = "nix-command flakes";
    nixPath = let
      entries = lib.mapAttrsToList (k: v: k+"="+v) (import ./npins);
    in ["${lib.concatStringsSep ":" entries}:flake"];
  };
}
