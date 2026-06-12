# vars (clan-style secret generators) for finix.
#
# The vars options + on-machine backend are imported in ./default.nix; this file
# enables the backend and declares the generic generators. The on-machine backend
# writes secrets to /etc/vars/secret/<gen>/<file> at runtime (the build needs no
# root and the closure carries no secrets). Per-feature generators live with
# their feature (e.g. wireguard VPN keys in ./wireguard.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  vars.settings.on-machine.enable = true;

  vars.generators = {
    "prompted" = {
      script = ''cp -R "$prompts"/. "$out/"'';
      # usage:
      # prompts."foo" = { };
      # files."foo".secret = true;
    };
    "templates" = {
      dependencies = [ "prompted" ];
      files = { };
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnused
      ];
      # fill out any template placeholders using our dependencies
      script = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (template: _: ''
          cp "$templates/${template}" "$out/${template}"
          echo "filling placeholders in template ${template}..."
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              parent:
              { placeholder, ... }:
              ''
                sed -i "s/${placeholder}/$(cat "$in/prompted/${parent}")/g" "$out/${template}"
                echo "- substituted ${parent}"
              ''
            ) config.vars.generators."prompted".files
          )}
        '') config.vars.generators."templates".files
      );
    };
  };
}
