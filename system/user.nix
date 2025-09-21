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
        nixos-conf-editor = pkgs.callPackage "${sources.nixos-conf-editor}/packages/nixos-conf-editor" { };
        hydrasect = pkgs.callPackage "${sources.hydrasect}/pkgs/by-name/hy/hydrasect/package.nix" { };
        nixpkgs-staging-bisecter = pkgs.callPackage "${sources.nixpkgs-staging-bisecter}/pkgs/by-name/ni/nixpkgs-staging-bisecter/package.nix" { };
        nix-bisect = pkgs.python3.pkgs.callPackage "${sources.nix-bisect}/package.nix" { };
      in
      with pkgs;
      [
        bat
        bluetuith
        btop
        fd
        jaq
        tea
        gurk-rs
        hydrasect
        keepassxc
        lazyjj
        mattermost-desktop
        moreutils
        nextcloud-client
        nixd
        nix-bisect
        nixpkgs-staging-bisecter
        nix-search
        nixfmt-rfc-style
        npins
        ripgrep
        signal-desktop-bin
        swaynotificationcenter
        tree
        transmission_4
        vlc
        wl-clipboard
        libreoffice-fresh
        nixos-conf-editor
        nixpkgs-review
        gh # dep of nixpkgs-review
        nix-init
        tor-browser
        nix-index
        zathura
      ];
  };
}
