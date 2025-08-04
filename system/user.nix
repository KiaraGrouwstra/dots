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
        tea
        gurk-rs
        keepassxc
        lazyjj
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
      ];
  };
}
