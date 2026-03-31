{ pkgs, ... }:
{
  _class = "homeManager";

  # Sync primary selection to clipboard so middle-click selections are
  # available via Ctrl+V. The reverse direction is intentionally omitted —
  # syncing clipboard→primary breaks cut/paste workflows in Electron apps
  # (e.g. Signal Desktop) by overwriting primary at the wrong moment.
  systemd.user.services.wl-clip-primary-to-clipboard = {
    Unit = {
      Description = "Sync primary selection to clipboard";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --primary --watch ${pkgs.wl-clipboard}/bin/wl-copy";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
