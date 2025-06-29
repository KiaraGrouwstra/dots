{
  lib,
  pkgs,
  ...
}:
let
  user = "kiara";
in
{
  security.pam.services.swaylock = {};

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
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      libnotify
      xdg-utils
      niri
    ];
  };
  systemd.user = {
    targets = {
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
  # system-level portal is needed for secrets
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = let
      common = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    in {
      inherit common;
      niri = common;
    };
    configPackages = [ pkgs.niri ];
  };
  home-manager.users.${user} = {
    options.programs.niri = {
      enable = lib.mkEnableOption "niri";
    };
    config = {
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
      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
      };
    };
  };

  services.displayManager.sessionPackages = lib.mkForce [
    pkgs.niri
  ];
}
