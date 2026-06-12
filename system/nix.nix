# Nix daemon settings for finix.
#
# Finix exposes nix config under `services.nix-daemon.settings` (freeform attrs
# written to nix.conf), not NixOS's `nix.settings`. We port the essential build
# settings; the NixOS-only machinery is dropped for v1:
#   - distributedBuilds / buildMachines  (no finix option; revisit if needed)
#   - nix.gc systemd timers              (port to fcron later if desired)
#   - nix-build-cgroup-reaper            (systemd-coupled; finit cgroup handling
#                                         may make it moot - revisit)
#   - the github-pat access-token templating via vars (revisit per-need)
{ ... }:
{
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
  };
}
