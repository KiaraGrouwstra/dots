# Finix system module set (finit as PID 1, not systemd).
#
# Imports the finix-community `laptop` profile (the `standard` stack: udev +
# elogind + NetworkManager) and layers the machine-specific config on top.
{
  modules,
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "kiara";
  sources = (import ../npins) { };
  system = "x86_64-linux";

  profiles = import "${sources.profiles}";
  community = import "${sources.community-modules}";

  specialArgs = {
    inherit sources system user;
    sysConfig = config;
  };

  homeModule = import ../home {
    inherit
      config
      pkgs
      sources
      user
      lib
      ;
  };
  userHmModule = homeModule.home-manager.users.${user};
in
{
  imports = [
    profiles.nixosModules.laptop
    community.nixosModules.home-manager
    community.nixosModules.soteria
    "${sources.finix}/modules/services/autologin"
    "${sources.vars}/options.nix"
    "${sources.vars}/backends/on-machine.nix"
    # noctalia's nixos-module is only a systemd *user* service launching the
    # shell; finix has no user session, so the shell is spawned by niri's
    # `spawn-at-startup "noctalia-shell"` instead (home dotfiles config.kdl).
    # The home-module (programs.noctalia-shell) supplies the package + config.
    ./hardware.nix
    ./disks.nix
    # bootloader (limine) comes from the laptop profile; Secure Boot is opt-in
    # and off for v1 (see README). No local boot module needed for now.
    ./user.nix
    ./vars.nix
    ./nix.nix
    ./wireguard.nix
    ./firewall.nix
    ./services.nix
    ./tts.nix
    ./niri
  ]
  # Native finix service/program modules, imported by reference from the
  # `modules` arg (= finix's `nixosModules`, passed through specialArgs).
  ++ (with modules; [
    # incus
    flatpak
    niri
    xwayland-satellite
    gnome-keyring
    doas
  ]);

  _module.args = specialArgs;

  nixpkgs.pkgs = import "${sources.nixpkgs}" {
    inherit system;
    config = {
      allowUnfree = true;
      # incus pulls in minio, currently flagged insecure upstream.
      # permittedInsecurePackages = [ "minio-2025-10-15T17-29-55Z" ];
    };
    overlays = [
      (final: prev: {
        # libseat's systemd logind backend RPATHs a split-output systemd whose
        # `lib` output lacks libsystemd.so.0 (it lives in systemd-minimal-libs),
        # so cage -> wlroots -> libseat.so.1 fails to load libsystemd ->
        # "cage: libsystemd.so.0: cannot open shared object file". Finix uses
        # elogind + the seatd daemon (services.seatd in ./disks.nix) for seat
        # management, so drop the logind backend entirely.
        seatd = prev.seatd.override { systemdSupport = false; };
      })
    ];
  };

  profiles.laptop.enable = true;
  profiles.laptop.hardwareSupport = "standard";

  networking.hostName = "nixos";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # Custom DNS (dns.sb). Finix has no `networking.nameservers`; the NM module is
  # minimal too, so push the servers through a NetworkManager conf.d drop-in
  # (NM's global-dns), matching what `networking.nameservers` does on NixOS.
  environment.etc."NetworkManager/conf.d/dns.conf".text = ''
    [global-dns-domains-*]
    servers=185.222.222.222,45.11.45.11
  '';

  # community HM module specialArgs only pass pkgs/lib/osConfig; the home/
  # submodules also expect sources/user/sysConfig. The home bridge below injects
  # them per-user (see home-manager.users.${user}.imports).
  home-manager.users.${user}.imports = [
    userHmModule
    {
      _module.args = {
        inherit sources user;
        sysConfig = config;
      };
      # finix has no systemd user session - drop units with no equivalent.
      services.kdeconnect.enable = lib.mkForce false;
      # The community HM module does not derive these from the system user the
      # way the NixOS HM module does; set them explicitly.
      home.username = user;
      home.homeDirectory = "/home/${user}";
      home.sessionVariables = {
        BROWSER = "firefox";
        XDG_CURRENT_DESKTOP = "X-Generic";
        NIX_AUTO_RUN = "1";
        NIX_AUTO_INSTALL = "1";
      };
      # nixpkgs/HM release skew is expected (we pin both independently).
      home.enableNixpkgsReleaseCheck = false;
    }
  ];
}
