{ pkgs, ... }:
{
  _class = "homeManager";

  systemd.user.services.mpris-proxy = {
    Unit = {
      Description = "Bluetooth MPRIS proxy";
      After = "bluetooth.target";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Restart = "on-failure";
    };
  };
}
