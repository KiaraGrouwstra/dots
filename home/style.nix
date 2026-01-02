{
  pkgs,
  ...
}:
let
  papirus = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "maroon";
  };
in
{
  home.packages = [
    papirus
  ];

  qt =
    let
      Appearance = {
        style = "kvantum";
        icon_theme = "Papirus-Dark";
        standar_dialogs = "xdgdesktopportal";
      };
    in
    {
      enable = true;
      qt5ctSettings = { inherit Appearance; };
      qt6ctSettings = { inherit Appearance; };
    };
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  # gtk =
  #   let
  #     iconTheme = {
  #       # https://github.com/catppuccin/papirus-folders#previews
  #       package = papirus;
  #       name = "Papirus-Dark";
  #     };
  #   in
  #   {
  #     enable = true;
  #     inherit iconTheme;
  #     gtk4 = { inherit iconTheme; };
  #     gtk3 = { inherit iconTheme; };
  #     gtk2 = { inherit iconTheme; };
  #   };
}
