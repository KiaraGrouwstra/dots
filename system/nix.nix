{
  config,
  lib,
  pkgs,
  ...
}:
{
  vars.generators = {
    # specify base secrets to prompt by `generate-vars`
    "prompted" = {
      # token from https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
      prompts."github-pat" = { };
      files."github-pat".secret = true;
    };
    # our templated secrets
    "templates" = {
      files."nix.conf" = {
        # `secret` here refers to the substituted file, not to the (un-sensitive) template
        secret = true;
        # map `config.nix.settings` to `nix.conf`, stolen from <nixpkgs/nixos/modules/config/nix.nix>
        template =
          let
            cfg = config.nix;
            mkValueString =
              v:
              if v == null then
                ""
              else if lib.isBool v then
                lib.boolToString v
              else if lib.isFloat v then
                lib.floatToString v
              else if
                (
                  lib.isInt v
                  || lib.isList v
                  || lib.isDerivation v
                  || builtins.isPath v
                  || lib.strings.isConvertibleWithToString v
                )
              then
                toString v
              else if lib.isString v then
                v
              else
                abort "The nix conf value: ${lib.toPretty { } v} can not be encoded";
            mkKeyValue = k: v: "${lib.escape [ "=" ] k} = ${mkValueString v}";
            mkKeyValuePairs = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList mkKeyValue attrs);
            isExtra = key: lib.hasPrefix "extra-" key;
          in
          pkgs.writeText "nix.conf" ''
            ${mkKeyValuePairs (lib.filterAttrs (key: value: !(isExtra key)) cfg.settings)}
            ${mkKeyValuePairs (lib.filterAttrs (key: value: isExtra key) cfg.settings)}
            ${cfg.extraOptions}
          '';
      };
    };
  };
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      # use a placeholder where we want our secret substituted in
      access-tokens = ''
        github.com=${config.vars.generators."prompted".files."github-pat".placeholder}
      '';
    };
  };
  # make the final file use our substituted var
  environment.etc."nix/nix.conf".source =
    lib.mkForce
      config.vars.generators."templates".files."nix.conf".path;
}
