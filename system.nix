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
  finix = import "${sources.finix}";
  lib = (import "${sources.nixpkgs}" { }).lib;
in
finix.lib.finixSystem {
  inherit lib;
  modules = [ ./system ];
}
