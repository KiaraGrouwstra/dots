{
  config,
  pkgs,
  system,
  user,
  sources,
  ...
}:
let
  inherit (pkgs) callPackage python3;
  flake-compat = src: import sources.flake-compat { inherit src; };
in
{
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = config.home-manager.users.kiara.programs.nushell.package;
    packages =
      let
        unstable = import sources.nixpkgs-unstable { };
        nixpkgs-staging-bisecter = callPackage "${sources.nixpkgs-staging-bisecter}/package.nix" { };
        nix-bisect = python3.pkgs.callPackage "${sources.nix-bisect}/package.nix" { };
        stremio-service = python3.pkgs.callPackage ./stremio-service.nix { };
        nix-init = (flake-compat sources.nix-init).outputs.packages.${system}.nix-init;
      in
      with pkgs;
      [
        antimicrox
        bluetuith
        btop
        exiftool # yazi
        mediainfo # yazi
        fd
        jaq
        tea
        unstable.gurk-rs
        hydrasect
        # iamb # https://github.com/NixOS/nixpkgs/issues/501937
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
        unstable.signal-desktop-bin
        swaynotificationcenter
        socat
        tree
        transmission_4
        unstable.vlc
        wl-clipboard
        thunar
        libreoffice-fresh
        nixpkgs-review
        gh # dep of nixpkgs-review
        watchman
        jujutsu
        jjui
        nix-init
        sox
        tor-browser
        tut
        nix-index
        zathura
        dconf
        stremio-service
        unar
        xdg-terminal-exec
        xterm-256color
        x-terminal-emulator
        x-www-browser
        xfce4-exo
      ];
  };
}
