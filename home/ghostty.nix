{ ... }:
{
  _class = "homeManager";

  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 10;
      theme = "noctalia";
      scrollback-limit = 50000;
      window-decoration = false;
      confirm-close-surface = false;
      cursor-style = "block";
      cursor-opacity = 0.1;
      custom-shader = "smear.glsl";
      keybind = [
        "alt+enter=unbind"
        "alt+0=reset_font_size"
        "alt+-=decrease_font_size:1"
        "alt+==increase_font_size:1"
        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "alt+4=goto_tab:4"
        "alt+5=goto_tab:5"
        "alt+6=goto_tab:6"
        "alt+7=goto_tab:7"
        "alt+8=goto_tab:8"
        "alt+9=last_tab"
        "alt+c=copy_to_clipboard"
        "alt+v=paste_from_clipboard"
        "alt+f=next_tab"
        "alt+shift+f=move_tab:1"
        "alt+d=previous_tab"
        "alt+shift+d=move_tab:-1"
        "alt+j=scroll_page_down"
        "alt+k=scroll_page_up"
        "alt+t=new_tab"
        "alt+o=new_window"
        "alt+q=close_surface"
      ];
    };
    # don't write to config outside nix
    systemd.enable = false;
  };
}
