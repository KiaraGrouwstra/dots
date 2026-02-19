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
        nixpkgs-staging-bisecter =
          callPackage
            "${sources.nixpkgs-staging-bisecter}/pkgs/by-name/ni/nixpkgs-staging-bisecter/package.nix"
            { };
        nix-bisect = python3.pkgs.callPackage "${sources.nix-bisect}/package.nix" { };
        stremio-service = python3.pkgs.callPackage ./stremio-service.nix { };
        nix-init = (flake-compat sources.nix-init).outputs.packages.${system}.nix-init;
      in
      with pkgs;
      [
        bat
        bluetuith
        btop
        exiftool # yazi
        mediainfo # yazi
        fd
        jaq
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
        nixfmt-rfc-style
        npins
        ripgrep
        unstable.signal-desktop-bin
        swaynotificationcenter
        tree
        transmission_4
        unstable.vlc
        wl-clipboard
        xfce.thunar
        libreoffice-fresh
        nixpkgs-review
        gh # dep of nixpkgs-review
        watchman
        jujutsu
        jjui
        nix-init
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
        xfce.exo
      ];
  };
}
