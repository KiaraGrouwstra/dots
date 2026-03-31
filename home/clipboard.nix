{ pkgs, ... }:
let
  wl-clip-sync-copy = pkgs.writeShellScriptBin "wl-clip-sync-copy" ''
    lock="/tmp/wl-clip-sync-$UID.lock"
    exec 9>"$lock"
    ${pkgs.util-linux}/bin/flock -n 9 || exit 0
    ${pkgs.wl-clipboard}/bin/wl-copy "$@"
  '';
in
{
  _class = "homeManager";

  home.packages = [ wl-clip-sync-copy ];

  # Bidirectional sync between primary selection and clipboard.
  # A shared flock prevents feedback loops: when one direction triggers the
  # other, the second watcher finds the lock held and exits immediately.
  systemd.user.services.wl-clip-primary-to-clipboard = {
    Unit = {
      Description = "Sync primary selection to clipboard";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --primary --watch wl-clip-sync-copy";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.wl-clip-clipboard-to-primary = {
    Unit = {
      Description = "Sync clipboard to primary selection";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch wl-clip-sync-copy --primary";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
