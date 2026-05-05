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
  flake-compat = src: import sources.flake-compat { inherit src; };
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
        exec = "${pkgs.wezterm}/bin/wezterm -e ${pkgs.transmission_4}/bin/transmission-cli %u";
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
      spd-say = import ./spd-say.nix { inherit pkgs; };
      claude-tts = pkgs.writeShellApplication {
        name = "claude-tts";
        runtimeInputs = [ pkgs.jq spd-say ];
        excludeShellChecks = [ "SC2016" ];
        text = ''
          MSG=$(jq -r '.last_assistant_message // empty')
          if [ -n "$MSG" ] && [ ''${#MSG} -gt 5 ]; then
            CLEAN=$(echo "$MSG" | tr '\n' ' ' | sed 's/```[^`]*```//g' | sed 's/`[^`]*`//g' | sed 's/  */ /g' | head -c 800)
            echo "$CLEAN" | spd-say -e
          fi
        '';
      };
    in
    {
      _class = "homeManager";

      imports = [
        "${sources.noctalia-shell}/nix/home-module.nix"
        (flake-compat sources.sbox).outputs.homeManagerModules.sbox
        ./dotfiles.nix
        ./firefox.nix
        ./git.nix
        ./helix.nix
        ./lazygit.nix
        ./neovim
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
        pkgs.claude-code-router
        exo-desktop
        magnet-handler
        pkgs.pywalfox-native
        respects-claude
        media-play-pause
        spd-say
        claude-tts
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
          appLauncher.terminalCommand = "wezterm -e";
          templates.activeTemplates =
            map
              (id: {
                inherit id;
                enabled = true;
              })
              [
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
            bzip2
            cpio
            gnutar
            gzip
            lhasa
            lzop
            p7zip
            unrar-free
            unzip
            xz
            zip
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
          # skills = {
          #   researching-with-deepwiki = "${sources.marketplace}/skills/asmayaseen/researching-with-deepwiki";
          # };
          # mcpServers.deepwiki = {
          #   type = "http";
          #   url = "https://mcp.deepwiki.com/mcp";
          # };
          # settings = {
          #   includeCoAuthoredBy = false;
          #   voiceEnabled = true;
          #   skipDangerousModePermissionPrompt = true;
          #   # theme = "dark";
          #   permissions = {
          #     # defaultMode = "auto";
          #     defaultMode = "plan";
          #     allow = [ "Bash(*)" "Read(*)" "Search(*)" "WebFetch(*)" ];
          #   };
          #   model = "opusplan";
          #   # model = "claude-sonnet-4-7";
          #   effortLevel = "medium";
          #   awaySummaryEnabled = false;
          #   showClearContextOnPlanAccept = true;
          #   attribution = {
          #     commit = "Assisted-by: Claude:claude-sonnet-4-7";
          #     pr = "Disclaimer: I used a coding agent in the creation of this patch.";
          #   };
          #   statusLine = {
          #     type = "command";
          #     command = "/home/kiara/.claude/statusline.sh";
          #   };
          #   env = {
          #     CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "47";
          #     CLAUDE_CODE_EFFORT_LEVEL = "medium";
          #     CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          #     CLAUDE_CODE_FORK_SUBAGENT = "1";
          #   };
          #   hooks = {
          #     Stop = [
          #       {
          #         hooks = [
          #           {
          #             type = "command";
          #             # command = "${claude-tts}/bin/claude-tts";
          #             command = "claude-tts";
          #             async = true;
          #           }
          #         ];
          #       }
          #     ];
          #   };
          # };
        };
        nix-index = {
          enable = true;
          enableNushellIntegration = true;
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
          settings.mgr.show_hidden = true;
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
        sbox = {
          enable = true;
          bind = {
            "$HOME/.cache" = {};
            "$HOME/.claude" = {};
            "$HOME/.claude.json" = {};
          };
          bindReadOnly = {
            "$HOME/.ssh/id_ed25519".to = "$HOME/.ssh/id_ed25519";
            "$HOME/.ssh/id_ed25519.pub".to = "$HOME/.ssh/id_ed25519.pub";
          };
          shareHistory = "project";
        };
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
