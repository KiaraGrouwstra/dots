{
  sysConfig,
  config,
  lib,
  pkgs,
  ...
}:
{
  _class = "homeManager";

  programs = {
    nushell = {
      enable = true;
      environmentVariables = lib.mkMerge [
        sysConfig.environment.variables
        config.home.sessionVariables
      ];
      extraConfig =
        # nu
        ''
          $env.config.show_banner = false
          $env.config.buffer_editor = "hx"
          $env.config.hooks.command_not_found = source ${./command-not-found.nu}
          $env.config.hooks.pre_prompt = [{||
            let elapsed = $env.CMD_DURATION_MS | into int | into duration -u ms
            if $elapsed >= 5sec {
              let body = $"Task completed in ($elapsed)"
              notify-send "Task Finished" $body
            }
          }]
        '';
      plugins = lib.attrValues {
        inherit (pkgs.nushellPlugins)
          gstat
          polars
          desktop_notifications
          ;
      };
      shellAliases = {
        jq = "jaq";
      };
    };
    nix-your-shell = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
