{ pkgs, sources, ... }:
let
  # Extract the animations block from the pinned sharkler-dots config.
  # Source: https://gitlab.com/sharkler/sharkler-dots/-/blob/a3938454846e71ca78eac86d22163397b20ebee5/.config/niri/config.kdl
  sharklersAnimations = pkgs.runCommand "sharkler-animations.kdl" { } ''
    awk '/^animations \{/{found=1} found{print} found && /^\}$/{exit}' \
      ${sources.sharkler-dots}/.config/niri/config.kdl > $out
  '';
in
{
  _class = "homeManager";
  home.file = {
    # Symlink nirimation animations dir so config.kdl can use relative includes.
    ".config/niri/nirimation".source = "${sources.nirimation}/animations";
    # Expose the sharkler-dots animations as an includable file alongside nirimation.
    ".config/niri/current-animations.kdl".source = sharklersAnimations;
  };
}
