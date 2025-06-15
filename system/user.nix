{
  config,
  lib,
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
        upstream = lib.lists.map (k: pkgs.${k}.overrideAttrs (_: { src = sources.${k}; })) [
          "lazyjj"
        ];
      in
      with pkgs;
      upstream ++
      [
        bat
        bluetuith
        bun
        fd
        jaq
        tea
        gurk-rs
        keepassxc
        mattermost-desktop
        moreutils
        nextcloud-client
        nixd
        nix-search
        nixfmt-rfc-style
        npins
        ripgrep
        signal-desktop-bin
        stremio
        tree
        transmission
        vlc
        wl-clipboard
        libreoffice-fresh
        nixos-conf-editor
        nixpkgs-review
        gh # dep of nixpkgs-review
        nix-init
        tor-browser
      ];
  };
}
