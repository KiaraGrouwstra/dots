let
  sources = import ./npins;
in
import "${sources.nixpkgs}/nixos" {
  configuration = ./configuration.nix;
}
