{
  config,
  lib,
  pkgs,
  ...
}:
{
  vars.generators = {
    "prompted" = {
      # TODO: use clan.core.vars' `prompts.<name>.persist`
      script = ''cp -R "$prompts"/. "$out/"'';
      # usage:
      # prompts."foo" = { };
      # files."foo".secret = true;
    };
    "templates" = rec {
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
        '') files
      );
    };
  };
}
