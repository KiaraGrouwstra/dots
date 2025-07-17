{
  lib,
  ...
}:
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
            # TODO: speed up using HM's `lib.file.mkOutOfStoreSymlink`
            # https://github.com/nix-community/home-manager/blob/460f1e9af95b081fb7e2022485b6c22b92085936/modules/files.nix#L84
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
    homeFolder ./dotfiles;
}
