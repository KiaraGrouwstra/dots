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
      # extraConfig =
      #   # nu
      #   ''
      #     $env.config.show_banner = false
      #     $env.config.buffer_editor = "hx"
      #     $env.config.hooks.command_not_found = source ${./command-not-found.nu}
      #     $env.config.hooks.pre_prompt = [{||
      #       let ms = ($env.CMD_DURATION_MS | into int)
      #       if ($ms | into duration -u ms) >= 5sec {
      #         let elapsed = if $ms >= 60000 {
      #             $"($ms / 60000 | math floor)min"
      #         } else if $ms >= 1000 {
      #             $"($ms / 1000 | math floor)sec"
      #         } else {
      #             $"($ms)ms"
      #         }
      #         notify-send $elapsed
      #       }
      #     }]
      #   '';
      settings = {
        show_banner = false;
      };
      plugins = lib.attrValues {
        inherit (pkgs.nushellPlugins)
          gstat
          polars
          # desktop_notifications  # incompatible with nushell 0.112.1
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
