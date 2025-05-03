# https://github.com/NixOS/nixpkgs/pull/295211
# The KDL document language (https://kdl.dev/)
{
  lib,
  pkgs,
  ...
}:
{

  type = (with lib.types; let
    # https://github.com/kdl-org/kdl/blob/main/SPEC.md#value
    untypedKdlValue = (nullOr (oneOf [ str bool number ])) // { description = "KDL value"; };
    kdlValue = either untypedKdlValue ((submodule {
      options = {
        type = lib.mkOption {
          type = nullOr str;
          default = null;
          description = ''
            [Type Annotation](https://github.com/kdl-org/kdl/blob/main/SPEC.md#type-annotation) of the value.
            Set to `null` to prevent generating a type annotation.
          '';
        };
        value = lib.mkOption {
          type = untypedKdlValue;
          description = ''
            The actual KDL value.
          '';
        };
      };
    }) // { description = "submodule: { type = /* type annotation */; value = /* KDL value */; }"; });
    node = submoduleWith {
      modules = lib.toList {
        options = {
          name = lib.mkOption {
            type = str;
            description = ''
              Name of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
            '';
          };
          type = lib.mkOption {
            type = nullOr str;
            default = null;
            description = ''
              [Type Annotation](https://github.com/kdl-org/kdl/blob/main/SPEC.md#type-annotation) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
              Set to `null` to prevent generating a type annotation.
            '';
          };
          arguments = lib.mkOption {
            type = listOf kdlValue;
            default = [ ];
            description = ''
              [Arguments](https://github.com/kdl-org/kdl/blob/main/SPEC.md#argument) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
            '';
          };
          properties = lib.mkOption {
            type = attrsOf kdlValue;
            default = { };
            description = ''
              [Properties](https://github.com/kdl-org/kdl/blob/main/SPEC.md#property) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
            '';
          };
          children = lib.mkOption {
            type = listOf (node // {
              # Prevent Nix from trying to recurse into suboptions or submodules, as this leads to a stack overflow
              getSubOptions = prefix: {};
              getSubModules = null;
            });
            default = [ ];
            description = ''
              [Children](https://github.com/kdl-org/kdl/blob/main/SPEC.md#children-block) of [KDL node](https://github.com/kdl-org/kdl/blob/main/SPEC.md#node).
            '';
          };
        };
      };
      description = "KDL node";
    };
    valueType = listOf node;
  in
  valueType);

  lib = {
    node = name: type: arguments: properties: children: { inherit name type arguments properties children; };
    typed = type: value: { inherit type value; };
  };

  generate = name: value: pkgs.callPackage ({ runCommand }: runCommand name {
    nativeBuildInputs = let
      json2kdl = pkgs.callPackage ./json2kdl.nix {};
    in [ json2kdl ];
    value = builtins.toJSON value;
    passAsFile = [ "value" ];
  } ''
    json2kdl "$valuePath" "$out"
  '') {};

}
