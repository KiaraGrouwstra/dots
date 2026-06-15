# Finix entry point (finix-port branch).
#
# Finix ships its own module tree evaluated via `lib.evalModules { class =
# "nixos"; }`; it does not call `nixpkgs/nixos`. The system module set lives in
# ./system (the finix port of what `main` keeps as the NixOS config). Build the
# toplevel with:
#   nix build -f system.nix config.system.build.toplevel
# and rebuild with ./finix-rebuild (nixos-rebuild-ng via finix's nixos-compat).
let
  sources = import ./npins;
  pkgs = import "${sources.nixpkgs}" { };
  # The pinned finix source is read-only; apply our in-repo patch (loud
  # finix-mount-all + switch-root gated on <task/mount-all/success>) before
  # importing it. See ./finix.patch.
  finixSrc = pkgs.applyPatches {
    name = "finix-patched";
    src = "${sources.finix}";
    patches = [ ./finix.patch ];
  };
  finix = import "${finixSrc}";
  lib = pkgs.lib;
in
finix.lib.finixSystem {
  inherit lib;
  modules = [ ./system ];
}
