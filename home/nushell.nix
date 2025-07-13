{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    nushell = {
      enable = true;
      environmentVariables = config.home.sessionVariables;
      extraConfig =
        # nu
        ''
          $env.config.show_banner = false
          $env.config.buffer_editor = "hx"
          $env.config.hooks.command_not_found = source ${./command-not-found.nu}
        '';
      plugins = lib.attrValues {
        inherit (pkgs.nushellPlugins)
          formats
          gstat
          highlight
          polars
          query
          skim
          units
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
