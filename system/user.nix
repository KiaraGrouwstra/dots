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
      in
      with pkgs;
      [
        bat
        bluetuith
        bun
        fd
        jaq
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
        vlc
        wl-clipboard
        libreoffice-fresh
        nixos-conf-editor
        nixpkgs-review
        gh # dep of nixpkgs-review
        tor-browser
      ];
  };
}
