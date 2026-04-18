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
        mode = "0644";
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
    package = pkgs.lix;
    # required, otherwise remote buildMachines aren't used
    distributedBuilds = true;
    # You can see the resulting builder-strings of this NixOS-configuration with "cat /etc/nix/machines".
    # These builder-strings are used by the Nix terminal tool, e.g.
    # when calling "nix build ...".
    buildMachines = [{
      # Will be used to call "ssh builder" to connect to the builder machine.
      # The details of the connection (user, port, url etc.)
      # are taken from your "~/.ssh/config" file.
      hostName = "forgejo-ci";
      # CPU architecture of the builder, and the operating system it runs.
      # Replace the line by the architecture of your builder, e.g.
      # - Normal Intel/AMD CPUs use "x86_64-linux"
      # - Raspberry Pi 4 and 5 use  "aarch64-linux"
      # - M1, M2, M3 ARM Macs use   "aarch64-darwin"
      # - Newer RISCV computers use "riscv64-linux"
      # See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/lib/systems/flake-systems.nix
      # If your builder supports multiple architectures
      # (e.g. search for "binfmt" for emulation),
      # you can list them all, e.g. replace with
      # systems = ["x86_64-linux" "aarch64-linux" "riscv64-linux"];
      system = "x86_64-linux";
      # Nix custom ssh-variant that avoids lots of "trusted-users" settings pain
      protocol = "ssh-ng";
      # default is 1 but may keep the builder idle in between builds
      maxJobs = 3;
      # how fast is the builder compared to your local machine
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }];

    settings = {
      # useful when the builder has a faster internet connection than yours
      builders-use-substitutes = true;
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
      automatic = false;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  # make the final file use our substituted var
  environment.etc."nix/nix.conf".source =
    lib.mkForce
      config.vars.generators."templates".files."nix.conf".path;
}
