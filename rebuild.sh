#!/usr/bin/env bash

cd $(dirname $0)
cmd=${1:-switch}
shift

pins=$(nix eval --json -f npins | jaq -r 'to_entries | map("\(.key)=\(.value)") | join(":")')
nix_path="${pins}:nixos-config=${PWD}/configuration.nix"
exec doas env NIX_PATH="${nix_path}" nixos-rebuild "$cmd" --fast "$@"
