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
      magnet-handler = pkgs.makeDesktopItem {
        type = "Application";
        name = "magnet-handler";
        desktopName = "Open Magnet Link";
        mimeTypes = [ "x-scheme-handler/magnet" ];
        exec = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.transmission_4}/bin/transmission-cli %u";
      };
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
      ];
      home.stateVersion = "24.11";
      home.packages = [
        exo-desktop
        magnet-handler
        pkgs.pywalfox-native
        respects-claude
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
          "application/x-desktop" = [
            "exo-open.desktop"
          ];
        };
      };
      programs.noctalia-shell = {
        enable = true;
        package = pkgs.callPackage "${sources.noctalia-shell}/nix/package.nix" { };
        settings.colorSchemes = {
          useWallpaperColors = true;
          darkMode = true;
        };
      };
      programs = {
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
