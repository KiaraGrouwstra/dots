#!/usr/bin/env bash
# https://jade.fyi/blog/pinning-nixos-with-npins/

cd $(dirname $0)
cmd=${1:-switch}
shift

nixpkgs_pin=$(nix-instantiate --raw --eval npins -A nixpkgs.outPath)
nix_path="nixos-config=${PWD}/configuration.nix:nixpkgs=${nixpkgs_pin}"
exec doas env NIX_PATH="${nix_path}" nixos-rebuild "$cmd" --no-reexec "$@"
