{
  config,
  pkgs,
  user,
  sources,
  ...
}:
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
        nixos-conf-editor = pkgs.callPackage "${sources.nixos-conf-editor}/packages/nixos-conf-editor" { };
        hydrasect = pkgs.callPackage "${sources.hydrasect}/pkgs/by-name/hy/hydrasect/package.nix" { };
        nixpkgs-staging-bisecter =
          pkgs.callPackage
            "${sources.nixpkgs-staging-bisecter}/pkgs/by-name/ni/nixpkgs-staging-bisecter/package.nix"
            { };
        nix-bisect = pkgs.python3.pkgs.callPackage "${sources.nix-bisect}/package.nix" { };
        stremio-service = pkgs.python3.pkgs.callPackage ./stremio-service.nix { };
      in
      with pkgs;
      [
        bat
        bluetuith
        btop
        exiftool # yazi
        fd
        jaq
        tea
        gurk-rs
        hydrasect
        iamb
        keepassxc
        lazyjj
        mattermost-desktop
        moreutils
        nextcloud-client
        nixd
        nix-bisect
        nixpkgs-staging-bisecter
        nps
        nixfmt-rfc-style
        npins
        ripgrep
        unstable.signal-desktop-bin
        swaynotificationcenter
        tree
        transmission_4
        vlc
        wl-clipboard
        xfce.thunar
        libreoffice-fresh
        nixos-conf-editor
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
        xdg-terminal-exec
        pkgs.xterm-256color
        pkgs.x-terminal-emulator
        pkgs.x-www-browser
        pkgs.xfce.exo
      ];
  };
}
