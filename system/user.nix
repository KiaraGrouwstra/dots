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
    packages = let
      nix-software-center = import sources.nix-software-center { };
      nixos-conf-editor = import "${sources.nixos-conf-editor}/packages/nixos-conf-editor" pkgs;
    in with pkgs; [
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
      nix-software-center
      nixos-conf-editor
      nixpkgs-review
    ];
  };
}
