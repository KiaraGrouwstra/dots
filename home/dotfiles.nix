{ lib, pkgs, config, ... }:
{
  home.file =
    let
      inherit (lib) strings lists attrsets;
      # recursively symlink any files in a directory from $HOME
      homeFolder =
        baseDir:
        let
          makePath = breadcrumbs: baseDir + "/${strings.concatStringsSep "/" breadcrumbs}";
          fileImport = breadcrumbs: _type: {
            "${strings.concatStringsSep "/" breadcrumbs}".source = makePath breadcrumbs;
          };
          iterDir =
            breadcrumbs:
            let
              fileSet = builtins.readDir (makePath breadcrumbs);
              processItem =
                location: type:
                let
                  breadcrumbs' = breadcrumbs ++ [ location ];
                in
                if type == "regular" then
                  [ (fileImport breadcrumbs' type) ]
                else if type == "directory" then
                  iterDir breadcrumbs'
                else
                  [ ];
            in
            attrsets.mapAttrsToList processItem fileSet;
        in
        attrsets.mergeAttrsList (lists.flatten (iterDir [ ]));
    in
    {
      # https://github.com/NixOS/nixpkgs/pull/412167
      "${config.xdg.configHome}/nushell/nix-your-shell.nu".source = pkgs.runCommand "nix-your-shell-config" {} ''${lib.getExe pkgs.nix-your-shell} nu >> "$out"'';
    } //
    homeFolder ./dotfiles;
}
