{
  lib,
  pkgs,
  ...
}:
let
  user = "kiara";
  cosmic-ext-alternative-startup = pkgs.rustPlatform.buildRustPackage {
    pname = "cosmic-ext-alternative-startup";
    # name = "cosmic-ext-alternative-startup";
    version = "0.1.0";
    src = <cosmic-ext-extra-sessions/cosmic-ext-alternative-startup>;
    cargoLock.lockFile = <cosmic-ext-extra-sessions/cosmic-ext-alternative-startup/Cargo.lock>;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libxkbcommon ];
    meta.mainProgram = "cosmic-ext-alternative-startup";
    # DISPLAY = ":0";
  };
  # # approach from https://github.com/Drakulix/cosmic-ext-extra-sessions/issues/8#issuecomment-2816771366
  # cosmicExtNiriSession =
  #   let
  #     scriptPackage = pkgs.writeScriptBin "start-cosmic-ext-niri" (
  #       lib.replaceStrings ["/usr/bin/"] [""]
  #         (lib.readFile <cosmic-ext-extra-sessions/niri/start-cosmic-ext-niri>)
  #     );
  #     cosmicNiriDesktop = pkgs.writeTextFile {
  #       name = "cosmic-niri.desktop";
  #       destination = "/share/wayland-sessions/cosmic-niri.desktop";
  #       text = lib.replaceStrings ["/usr/local/bin/"] [""]
  #         (lib.readFile <cosmic-ext-extra-sessions/niri/cosmic-ext-niri.desktop>);
  #     };
  #   in
  #   pkgs.symlinkJoin {
  #     name = "cosmic-ext-niri-session";
  #     paths = [
  #       cosmicNiriDesktop
  #       # runtimeInputs = [pkgs.systemd pkgs.dbus specialArgs.inputs.nixos-cosmic.packages.x86_64-linux.cosmic-session pkgs.bash pkgs.coreutils];
  #       scriptPackage
  #     ];
  #     passthru.providedSessions = [ "cosmic-niri" ];
  #   };

in
{
  # approach from https://github.com/linuxmobile/kaku/compare/niri...niri_cosmic, if fails try `exec cosmic-session niri`
  services.displayManager.sessionPackages = [
    ((
        pkgs.writeTextFile {
          name = "cosmic-on-niri";
          destination = "/share/wayland-sessions/COSMIC-on-niri.desktop";
          text = ''
            [Desktop Entry]
            Name=COSMIC-on-niri
            Comment=This session logs you into the COSMIC desktop on niri
            Type=Application
            DesktopNames=niri
            Exec=${pkgs.writeShellApplication {
              name = "start-cosmic-ext-niri";
              runtimeInputs = [pkgs.systemd pkgs.dbus pkgs.cosmic-session pkgs.bash pkgs.coreutils];
              text = ''
                set -e

                # From: https://people.debian.org/~mpitt/systemd.conf-2016-graphical-session.pdf

                if command -v systemctl >/dev/null; then
                    # robustness: if the previous graphical session left some failed units,
                    # reset them so that they don't break this startup
                    for unit in $(systemctl --user --no-legend --state=failed --plain list-units | cut -f1 -d' '); do
                        partof="$(systemctl --user show -p PartOf --value "$unit")"
                        for target in cosmic-session.target graphical-session.target; do
                            if [ "$partof" = "$target" ]; then
                                systemctl --user reset-failed "$unit"
                                break
                            fi
                        done
                    done
                fi

                # use the user's preferred shell to acquire environment variables
                # see: https://github.com/pop-os/cosmic-session/issues/23
                if [ -n "''${SHELL:-}" ]; then
                    # --in-login-shell: our flag to indicate that we don't need to recurse any further
                    if [ "''${1:-}" != "--in-login-shell" ]; then
                        # `exec -l`: like `login`, prefixes $SHELL with a hyphen to start a login shell
                        exec bash -c "exec -l ${"'"}''${SHELL}' -c ${"'"}''${0} --in-login-shell'"
                    fi
                fi

                export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:=niri}"
                export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:=wayland}"
                export XCURSOR_THEME="''${XCURSOR_THEME:=Cosmic}"
                export _JAVA_AWT_WM_NONREPARENTING=1
                export GDK_BACKEND=wayland,x11
                export MOZ_ENABLE_WAYLAND=1
                export QT_QPA_PLATFORM="wayland;xcb"
                export QT_AUTO_SCREEN_SCALE_FACTOR=1
                export QT_ENABLE_HIGHDPI_SCALING=1

                if command -v systemctl >/dev/null; then
                    # set environment variables for new units started by user service manager
                    systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
                fi
                # Run cosmic-session
                if [[ -z "''${DBUS_SESSION_BUS_ADDRESS}" ]]; then
                    exec dbus-run-session -- cosmic-session niri --session
                else
                    exec cosmic-session niri --session
                fi
              '';
            }}/bin/start-cosmic-ext-niri
          '';
        }
      )
      .overrideAttrs
      (old: {
        passthru.providedSessions = ["COSMIC-on-niri"];
      }))
  ];

  hardware.graphics.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;
  services = {
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
    # displayManager = {
    #   # defaultSession = "niri";
    #   sessionPackages = [
    #     # pkgs.niri
    #     # cosmicExtNiriSession
    #   ];
    # };
  };
  environment.systemPackages = with pkgs; [
    cosmic-ext-alternative-startup
    # cosmicExtNiriSession
    xdg-utils
    niri
    cosmic-greeter
    cosmic-launcher
    cosmic-applibrary
  ];
  systemd.user.services.niri-flake-polkit = {
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
}
