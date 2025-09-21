#!/usr/bin/env bash

cd $(dirname $0)
cmd=${1:-switch}
shift

exec doas nixos-rebuild "$cmd" --no-reexec "$@"
