# Nix daemon settings for finix.
#
# Finix exposes nix config under `services.nix-daemon.settings` (freeform attrs
# written to nix.conf), not NixOS's `nix.settings`. We port the essential build
# settings; the NixOS-only machinery is dropped for v1:
#   - distributedBuilds / buildMachines  (no finix option; revisit if needed)
#   - nix.gc systemd timers              (port to fcron later if desired)
#   - nix-build-cgroup-reaper            (systemd-coupled; finit cgroup handling
#                                         may make it moot - revisit)
#
# The github-pat access-token is injected at runtime via vars, mirroring main:
# the rendered nix.conf carries a placeholder, the `templates` generator
# substitutes the real secret into a runtime copy, and we force the etc source
# at it. So the build needs no token and the closure carries no secret. Same
# pattern as the wireguard task in ./wireguard.nix.
{
  config,
  lib,
  pkgs,
  sources,
  ...
}:
{
  vars.generators = {
    # token from https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
    "prompted".prompts."github-pat" = { };
    "prompted".files."github-pat".secret = true;

    "templates".files."nix.conf" = {
      # `secret` here refers to the substituted file, not the placeholder template.
      secret = true;
      mode = "0644";
      # render nix.conf from the daemon settings the same way finix's own
      # configFile does (key = space-joined value), with the placeholder embedded.
      template =
        (pkgs.formats.nixConf {
          package = config.services.nix-daemon.package;
          version = config.services.nix-daemon.package.version;
        }).generate
          "nix.conf"
          (
            lib.mapAttrs (
              _: v: if builtins.isList v then lib.concatStringsSep " " v else v
            ) config.services.nix-daemon.settings
          );
    };
  };

  services.nix-daemon.settings = {
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
    substituters = [
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    # placeholder substituted in at runtime by the `templates` generator
    access-tokens = "github.com=${config.vars.generators."prompted".files."github-pat".placeholder}";
    builders-use-substitutes = true;
    auto-optimise-store = false;
    cores = 0;
    max-jobs = "auto";
    require-sigs = true;
    sandbox = true;
    fallback = true;
    connect-timeout = 1;
    download-attempts = 2;
    auto-allocate-uids = true;
    use-cgroups = true;
    flake-registry = "";
    extra-system-features = [
      "uid-range"
    ];
    system-features = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
      "uid-range"
    ];
    extra-sandbox-paths = [
      "/dev/net"
    ];
    nix-path = lib.mapAttrsToList (k: v: k + "=" + v) sources;
  };

  # point the live nix.conf at the runtime-templated copy (with the real token)
  environment.etc."nix/nix.conf".source = lib.mkForce config.vars.generators."templates".files."nix.conf".path;
}
