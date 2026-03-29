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
  gtk =
    let
      iconTheme = {
        # https://github.com/catppuccin/papirus-folders#previews
        package = papirus;
        name = "Papirus-Dark";
      };
    in
    {
      enable = true;
      inherit iconTheme;
      theme = {
        package = pkgs.catppuccin-gtk.override {
          accents = [ "maroon" ];
          variant = "mocha";
        };
        name = "catppuccin-mocha-maroon-standard";
      };
      # gtk-application-prefer-dark-theme is needed for GTK3 apps (e.g. Thunar)
      # since color-scheme = prefer-dark only affects GTK4/libadwaita
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      # GTK4 apps use libadwaita which reads color-scheme from dconf; don't override with custom theme
      gtk4.theme = null;
    };
}
