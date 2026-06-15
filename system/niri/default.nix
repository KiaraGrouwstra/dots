{
  pkgs,
  ...
}:
{
  security.pam.services.swaylock = { };

  services = {
    displayManager.defaultSession = "niri";
    gnome.gnome-keyring.enable = true;
    geoclue2 = {
      enable = true;
      enableWifi = true;
    };
  };

  hardware.graphics.enable = true;
  environment = {
    variables = {
      # DISPLAY = ":0"; # xwayland-satellite
      NIXOS_OZONE_WL = "1";
      EDITOR = "hx";
    };
    systemPackages = with pkgs; [
      libnotify
      xwayland-satellite
      xdg-utils
      niri
    ];
  };
  systemd.packages = [ pkgs.xwayland-satellite ];
  systemd.user = {
    targets.graphical-session.wants = [ "xwayland-satellite.service" ];
    services.xwayland-satellite.wantedBy = [ "graphical-session.target" ];
    services.niri-flake-polkit = {
      description = "PolicyKit Authentication Agent provided by niri-flake";
      wantedBy = [ "niri.service" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
  # system-level portal is needed for secrets
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config =
      let
        common = {
          default = [
            "wlr"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      in
      {
        inherit common;
        niri = common;
      };
    configPackages = [ pkgs.niri ];
  };
}
