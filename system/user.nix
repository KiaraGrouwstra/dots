{
  config,
  lib,
  pkgs,
  system,
  user,
  sources,
  ...
}:
let
  inherit (pkgs) callPackage python3;
  flake-compat = src: import sources.flake-compat { inherit src; };

  # Conventional command-name wrappers other tools shell out to. On NixOS these
  # came from a `nixpkgs.overlays` entry (finix exposes no `overlays` option), but
  # they override nothing - they are plain `writeShellScriptBin` packages, so we
  # inline them here where they are used. `$BROWSER` is set in home.sessionVariables.
  cmdWrappers = lib.mapAttrsToList (name: command: pkgs.writeShellScriptBin name ''${command} "$@"'') {
    xterm-256color = "xdg-terminal-exec";
    x-terminal-emulator = "xdg-terminal-exec";
    x-www-browser = "$BROWSER";
  };
in
{
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      # "incus-admin"
      # "nitrokey"
    ];
    shell = config.home-manager.users.kiara.programs.nushell.package;
    packages =
      let
        unstable = import "${sources.nixpkgs-unstable}" { };
        nixpkgs-staging-bisecter = callPackage "${sources.nixpkgs-staging-bisecter}/package.nix" { };
        nix-bisect = python3.pkgs.callPackage "${sources.nix-bisect}/package.nix" { };
        stremio-service = python3.pkgs.callPackage ./stremio-service.nix { };
        inherit ((flake-compat sources.nix-init).outputs.packages.${system}) nix-init;
        inherit ((flake-compat sources.kimi-cli).outputs.packages.${system}) kimi-cli;
      in
      with pkgs;
      [
        antimicrox
        bitwarden-cli
        bluetuith
        btop
        dino
        exiftool # yazi
        mediainfo # yazi
        fd
        jaq
        jq
        tea
        unstable.gurk-rs
        hydrasect
        iamb
        keepassxc
        lazyjj
        mattermost-desktop
        moreutils
        nextcloud-client
        nixd
        nix-bisect
        nix-derivation
        nixpkgs-staging-bisecter
        nps
        nixfmt
        npins
        playerctl
        python3
        ripgrep
        unstable.signal-desktop
        socat
        tree
        transmission_4
        unstable.vlc
        wl-clipboard
        thunar
        libreoffice-fresh
        nixpkgs-reviewFull
        gh # dep of nixpkgs-review
        watchman
        jujutsu
        jjui
        nix-init
        nix-output-monitor
        sox
        tor-browser
        tut
        kimi-cli
        zathura
        dconf
        stremio-service
        unar
        xdg-terminal-exec
        xfce4-exo
      ]
      ++ cmdWrappers;
  };
}
