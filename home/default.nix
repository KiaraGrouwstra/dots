{
  config,
  pkgs,
  sources,
  user,
  ...
}:
let
  sysConfig = config;
  pay-respects-fork = pkgs.rustPlatform.buildRustPackage {
    pname = "pay-respects";
    version = "0.7.12-instant-mode";
    src = sources."pay-respects";
    cargoLock.lockFile = "${sources."pay-respects"}/Cargo.lock";
    cargoBuildFlags = [ "--workspace" ];
    meta.mainProgram = "pay-respects";
  };
in
{
  _class = "nixos";

  home-manager.users.${user} =
    { config, ... }:
    let
      exo-desktop = (
        let
          command = "${pkgs.xfce4-exo}/bin/exo-open";
        in
        pkgs.makeDesktopItem {
          type = "Application";
          name = "exo-open";
          desktopName = "Exo-Open";
          mimeTypes = [
            "application/x-desktop"
          ];
          tryExec = command;
          exec = command;
        }
      );
      aunpack-desktop =
        let
          mimeTypes = [
            "application/gzip"
            "application/x-7z-compressed"
            "application/x-bzip2"
            "application/x-compressed-tar"
            "application/x-cpio"
            "application/x-gtar"
            "application/x-lha"
            "application/x-lzop"
            "application/x-tar"
            "application/x-xz-compressed-tar"
            "application/zip"
            "application/x-rar"
          ];
        in
        pkgs.makeDesktopItem {
          type = "Application";
          name = "aunpack";
          desktopName = "Aunpack";
          inherit mimeTypes;
          exec = "${config.programs.atool.finalPackage}/bin/atool -x %f";
          terminal = true;
          noDisplay = true;
        };
      magnet-handler = pkgs.makeDesktopItem {
        type = "Application";
        name = "magnet-handler";
        desktopName = "Open Magnet Link";
        mimeTypes = [ "x-scheme-handler/magnet" ];
        exec = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.transmission_4}/bin/transmission-cli %u";
      };
      media-play-pause = pkgs.callPackage ./media-play-pause.nix { };
      respects-claude = pkgs.writeShellApplication {
        name = "_pay-respects-fallback-100-claude";
        text = ''
                    last_command="''${_PR_LAST_COMMAND:-}"
                    error_msg="''${_PR_ERROR_MSG:-}"
                    [ -z "$last_command" ] && exit 0
                    suggestion=$(claude -p "The following shell command failed.
          Command: $last_command
          Error: $error_msg

          Reply with ONLY the corrected shell command. No explanation, no markdown, no backticks." 2>/dev/null)
                    if [ -n "$suggestion" ]; then
                      printf '%s\n<_PR_BR>\n' "$suggestion"
                    fi
        '';
      };
    in
    {
      _class = "homeManager";

      imports = [
        "${sources.noctalia-shell}/nix/home-module.nix"
        ./dotfiles.nix
        ./firefox.nix
        ./git.nix
        ./helix.nix
        ./lazygit.nix
        ./niri.nix
        ./nushell.nix
        ./style.nix
        ./wezterm.nix
        ./ghostty.nix
        ./notifications.nix
        ./dictation.nix
        ./mpris-proxy.nix
      ];
      home.stateVersion = "24.11";
      home.packages = [
        aunpack-desktop
        exo-desktop
        magnet-handler
        pkgs.pywalfox-native
        respects-claude
        media-play-pause
      ];
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      xdg.systemDirs.data = [
        "/run/current-system/sw/share"
        "/etc/profiles/per-user/${user}/share"
        "/home/${user}/.nix-profile/share"
        "/home/${user}/.local/share"
        "${sysConfig.services.displayManager.sessionData.desktops}/share"
      ];
      xdg.mimeApps = {
        enable = true;
        defaultApplicationPackages = [
          pkgs.zathura
          config.programs.firefox.package
          pkgs.yazi
          pkgs.thunar
          config.programs.helix.package
          config.programs.neovim.package
          pkgs.libreoffice
          pkgs.vlc
          exo-desktop
        ];
        defaultApplications = {
          "x-scheme-handler/magnet" = [ "magnet-handler.desktop" ];
          "application/x-desktop" = [ "exo-open.desktop" ];
          "application/gzip" = [ "aunpack.desktop" ];
          "application/x-7z-compressed" = [ "aunpack.desktop" ];
          "application/x-bzip2" = [ "aunpack.desktop" ];
          "application/x-compressed-tar" = [ "aunpack.desktop" ];
          "application/x-cpio" = [ "aunpack.desktop" ];
          "application/x-gtar" = [ "aunpack.desktop" ];
          "application/x-lha" = [ "aunpack.desktop" ];
          "application/x-lzop" = [ "aunpack.desktop" ];
          "application/x-tar" = [ "aunpack.desktop" ];
          "application/x-xz-compressed-tar" = [ "aunpack.desktop" ];
          "application/zip" = [ "aunpack.desktop" ];
          "application/x-rar" = [ "aunpack.desktop" ];
        };
      };
      programs.noctalia-shell = {
        enable = true;
        package = pkgs.callPackage "${sources.noctalia-shell}/nix/package.nix" { };
        settings = {
          colorSchemes = {
            useWallpaperColors = true;
            darkMode = true;
          };
          templates.activeTemplates = map (id: { inherit id; enabled = true; }) [
            "cava"
            "gtk"
            "ghostty"
            "helix"
            "pywalfox"
            "qt"
            "niri"
            "wezterm"
            "yazi"
          ];
        };
      };
      programs = {
        atool = {
          enable = true;
          settings = {
            path_unrar = "unrar-free";
          };
          extraPackages = with pkgs; [
            bzip2 cpio gnutar gzip lhasa lzop p7zip unrar-free unzip xz zip
          ];
        };
        bat = {
          enable = true;
          config = {
            style = "plain";
            paging = "never";
          };
        };
        claude-code = {
          enable = true;
          settings = {
            includeCoAuthoredBy = false;
            voiceEnabled = true;
            skipDangerousModePermissionPrompt = true;
            # theme = "dark";
            # permissions.defaultMode = "auto";
            permissions.defaultMode = "bypassPermissions";
            statusLine = {
              type = "command";
              command = "/home/kiara/.claude/statusline.sh";
            };
            hooks.Notification = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "notify-send 'Claude Code' 'Claude Code needs your attention'";
                  }
                ];
              }
            ];
          };
        };
        oh-my-posh = {
          enable = true;
          enableNushellIntegration = true;
          useTheme = "catppuccin";
        };
        tealdeer.enable = true;
        pay-respects = {
          enable = true;
          enableNushellIntegration = true;
          package = pay-respects-fork;
          rules._PR_GENERAL.match_err = [
            {
              pattern = [
                "nu::shell::external_command"
                "command not found"
                "unknown command"
              ];
              suggest = [
                "#[executable(nix-shell), !cmd_contains(nix-shell)]\nnix-shell -p {{command[0]}} --run '{{command}}'"
              ];
            }
          ];
        };
        yazi = {
          enable = true;
          shellWrapperName = "yy";
          keymap.mgr.prepend_keymap =
            let
              repeat = n: cmd: builtins.genList (_: cmd) n;
            in
            [
              {
                on = "J";
                run = repeat 5 "arrow next";
                desc = "Move down 5 files";
              }
              {
                on = "K";
                run = repeat 5 "arrow prev";
                desc = "Move up 5 files";
              }
            ];
        };
        chromium.enable = true;
      };
      services.kdeconnect.enable = true;
    };

  networking.firewall = rec {
    # KDE Connect
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
