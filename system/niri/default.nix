# Desktop: niri session, xwayland-satellite, soteria polkit agent, steam, fonts.
#
# The laptop profile already brings regreet + greetd, pipewire/wireplumber,
# graphics, gnome-keyring, and xdg portals. This module enables the niri session
# and the bits layered on top. noctalia shell is launched by niri
# (spawn-at-startup) using the home-module package/config; its network/VPN
# panels rely on nmcli from NetworkManager.
{
  pkgs,
  ...
}:
{
  programs.niri.enable = true;
  programs.xwayland-satellite.enable = true;

  # Session-wide environment. Finix has no `environment.variables`; the
  # equivalent is pam_env via `security.pam.environment` (NixOS routes the same
  # vars through pam too). `.override` forces the value over any inherited one.
  #   DISPLAY        - xwayland-satellite's rootless X server
  #   NIXOS_OZONE_WL - wayland backend for electron/chromium apps
  #   EDITOR         - helix
  security.pam.environment = {
    # DISPLAY.override = ":0";
    NIXOS_OZONE_WL.override = "1";
    EDITOR.override = "hx";
  };

  # Polkit auth agent for the standalone wayland session (no DE agent).
  # Replaces the niri-flake systemd-user polkit unit (no user session on finix).
  services.soteria.enable = true;

  # Steam: finix has no programs.steam module, but the nixpkgs FHS wrapper
  # "just works" when added directly (per finix discussions/1).
  environment.systemPackages = [ pkgs.steam ];

  fonts.enableDefaultPackages = true;
}
