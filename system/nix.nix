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
          (pkgs.formats.nixConf {
            package = config.nix.package;
            version = config.nix.package.version;
          }).generate
            "nix.conf"
            (
              lib.mapAttrs (_: v: if builtins.isList v then lib.concatStringsSep " " v else v) config.nix.settings
            );
      };
    };
  };
  nix = {
    settings = {
      allowed-users = [
        "*"
      ];
      auto-optimise-store = false;
      builders = null;
      cores = 0;
      max-jobs = "auto";
      require-sigs = true;
      sandbox = true;
      sandbox-fallback = false;
      substituters = [
        "https://cache.nixos.org/"
      ];
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
        "uid-range"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-substituters = [ ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      trusted-users = [
        "root"
        "@wheel"
        "kiara"
      ];
      # use a placeholder where we want our secret substituted in
      access-tokens = ''
        github.com=${config.vars.generators."prompted".files."github-pat".placeholder}
      '';
      # allow offline builds
      flake-registry = "";
      fallback = true;
      connect-timeout = 1;
      download-attempts = 2;
      # nspawn-containers
      auto-allocate-uids = true;
      extra-system-features = [
        "uid-range"
      ];
      extra-sandbox-paths = [
        "/dev/net" # to make nspawn↔qemu networking work
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  # make the final file use our substituted var
  # environment.etc."nix/nix.conf".source =
  #   lib.mkForce
  #     config.vars.generators."templates".files."nix.conf".path;
}
