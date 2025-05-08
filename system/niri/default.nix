{
  lib,
  pkgs,
  ...
}:
let
  user = "kiara";
  cosmic-ext-alternative-startup = pkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-ext-alternative-startup";
    version = "0.1.0";
    src = <cosmic-ext-extra-sessions/cosmic-ext-alternative-startup>;
    cargoLock.lockFile = <cosmic-ext-extra-sessions/cosmic-ext-alternative-startup/Cargo.lock>;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libxkbcommon ];
    meta.mainProgram = "cosmic-ext-alternative-startup";
  };
  customStartup = (
  (
    let
      scriptPackage = pkgs.writeShellApplication {
        name = "start-cosmic-ext-niri";
        runtimeInputs = [pkgs.systemd pkgs.dbus pkgs.cosmic-session pkgs.bash pkgs.coreutils];
        text = ''
        set -e
        export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:=cosmic}"
        export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:=wayland}"
        export XCURSOR_THEME="''${XCURSOR_THEME:=Cosmic}"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export GDK_BACKEND=wayland,x11
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM="wayland;xcb"
        export QT_AUTO_SCREEN_SCALE_FACTOR=1
        export QT_ENABLE_HIGHDPI_SCALING=1
        systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
        exec dbus-run-session -- cosmic-session niri --session
      '';
    };
  in
    pkgs.writeTextFile {
      name = "cosmic-on-niri";
      destination = "/share/wayland-sessions/COSMIC-on-niri.desktop";
      text = ''
        [Desktop Entry]
        Name=COSMIC-on-niri
        Comment=This session logs you into the COSMIC desktop on niri
        Type=Application
        DesktopNames=niri
        Exec=${scriptPackage}/bin/start-cosmic-ext-niri
      '';
    }
  )
  .overrideAttrs
  (old: {
    passthru.providedSessions = ["COSMIC-on-niri"];
  }));

in
{
  # approach from https://github.com/linuxmobile/kaku/compare/niri...niri_cosmic, if fails try `exec cosmic-session niri`
  services = {
    displayManager.defaultSession = "niri";
    geoclue2 = {
      enable = true;
      enableWifi = true;
    };
  };

  hardware.graphics.enable = true;
  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
    };
    sessionVariables = {
      COSMIC_DATA_CONTROL_ENABLED = 1;
    };
    systemPackages = with pkgs; [
      libnotify
      xwayland-satellite
      cosmic-ext-alternative-startup
      xdg-utils
      niri
    ];
  };
  systemd.user = {
    targets = {
      graphical-session.wants = [ "xwayland-satellite.service" ];
      # boot with niri rather than the default cosmic-session
      cosmic-session.enable = false;
    };
    services.niri-flake-polkit = {
      description = "PolicyKit Authentication Agent provided by niri-flake";
      wantedBy = [ "niri.service" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
  home-manager.users.${user} = {
    options.programs.niri = {
      enable = lib.mkEnableOption "niri";
    };
    config = {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
          xdg-desktop-portal-cosmic
        ];
        config.common.default = [ "*" ];
        configPackages = [ pkgs.niri ];
      };
      xdg.configFile.niri-config = {
        enable = true;
        target = "niri/config.kdl";
        source =
        let
          kdl = pkgs.callPackage ./kdl.nix { };
          typed = kdl.lib.node;
          # use json2kdl's performance with niri-specific syntax sugar:
          # https://github.com/sodiboo/niri-flake/blob/main/kdl.nix
          node = name: arguments: children: let
            inherit (lib.foldl (
              self: this:
                if lib.isAttrs this
                then self // {props = self.props // this;}
                else self // {args = self.args ++ [this];}
            ) {
              args = [];
              props = {};
            } (lib.toList arguments)) args props;
          in typed name null args props children;
          plain = name: children: node name [] children;
          leaf = name: arguments: node name arguments [];
          flag = name: node name [] [];
          niri-config = kdl.generate "niri.kdl" (import ./config.nix { inherit node plain leaf flag; });
        in
          pkgs.runCommand "config.kdl"
            {
              config = niri-config;
              buildInputs = [ pkgs.niri ];
            }
            ''
              niri validate -c $config
              cp $config $out
            '';
      };
      programs.niri.enable = true;
    };
  };

  services.displayManager.sessionPackages = lib.mkForce [
    customStartup
  ];
}
