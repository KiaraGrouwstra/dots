# kdl helpers from https://github.com/sodiboo/niri-flake/blob/main/kdl.nix
{
  lib,
  node,
  plain,
  leaf,
  flag,
  ...
}:
let
  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (lib.splitString " " cmd);
in
[
  # needed for noctalia theming, but my manual validate does not like this,
  # see flake.nix in https://github.com/sodiboo/niri-flake/pull/1548/files
  # (leaf "include" "noctalia.kdl")

  (plain "input" [
    (plain "keyboard" [
      (plain "xkb" [
        # You can set rules, model, layout, variant and options.
        # For more information, see xkeyboard-config(7).
        (leaf "layout" "us")
        (leaf "options" "caps:escape,compose:sclk")
      ])

      # You can set the keyboard repeat parameters. The defaults match wlroots and sway.
      # Delay is in milliseconds before the repeat starts. Rate is in characters per second.
      (leaf "repeat-delay" 600)
      (leaf "repeat-rate" 25)

      # Niri can remember the keyboard layout globally (the default) or per-window.
      # - "global" - layout change is global for all windows.
      # - "window" - layout is tracked for each window individually.
      (leaf "track-layout" "global")
    ])

    # Next sections include libinput settings.
    # Omitting settings disables them, or leaves them at their default values.
    (plain "touchpad" [
      (flag "tap")
      # (flag "dwt")
      # (flag "dwtp")
      (flag "natural-scroll")
      (leaf "accel-speed" 0.2)
      (leaf "accel-profile" "flat")
      (leaf "tap-button-map" "left-middle-right")
      (leaf "scroll-method" "two-finger")
      (leaf "click-method" "clickfinger")
    ])

    (plain "mouse" [
      # (flag "natural-scroll")
      (leaf "scroll-method" "on-button-down")
      (leaf "accel-speed" 0.2)
      (leaf "accel-profile" "flat")
    ])

    (plain "trackpoint" [
      (flag "natural-scroll")
      (leaf "accel-speed" 0.2)
      (leaf "accel-profile" "flat")
    ])

    (plain "tablet" [
      # Set the name of the output (see below) which the tablet will map to.
      # If this is unset or the output doesn't exist, the tablet maps to one of the
      # existing outputs.
      (leaf "map-to-output" "eDP-1")
    ])

    (plain "touch" [
      # Set the name of the output (see below) which touch input will map to.
      # If this is unset or the output doesn't exist, touch input maps to one of the
      # existing outputs.
      (leaf "map-to-output" "eDP-1")
    ])

    # By default, niri will take over the power button to make it sleep
    # instead of power off.
    # Uncomment this if you would like to configure the power button elsewhere
    # (i.e. logind.conf).
    # (flag "disable-power-key-handling")
  ])

  # # You can configure outputs by their name, which you can find
  # # by running `niri msg outputs` while inside a niri instance.
  # # The built-in laptop monitor is usually called "eDP-1".
  # (node "output" "eDP-1" [
  #   # Uncomment this line to disable this output.
  #   # (flag "off")

  #   # Scale is a floating-point number, but at the moment only integer values work.
  #   (leaf "scale" 2.0)

  #   # Transform allows to rotate the output counter-clockwise, valid values are:
  #   # normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
  #   (leaf "transform" "normal")

  #   # Resolution and, optionally, refresh rate of the output.
  #   # The format is "<width>x<height>" or "<width>x<height>@<refresh rate>".
  #   # If the refresh rate is omitted, niri will pick the highest refresh rate
  #   # for the resolution.
  #   # If the mode is omitted altogether or is invalid, niri will pick one automatically.
  #   # Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
  #   (leaf "mode" "1920x1080@120.030")

  #   # Position of the output in the global coordinate space.
  #   # This affects directional monitor actions like "focus-monitor-left", and cursor movement.
  #   # The cursor can only move between directly adjacent outputs.
  #   # Output scale has to be taken into account for positioning:
  #   # outputs are sized in logical, or scaled, pixels.
  #   # For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080,
  #   # so to put another output directly adjacent to it on the right, set its x to 1920.
  #   # It the position is unset or results in an overlap, the output is instead placed
  #   # automatically.
  #   (leaf "position" { x=1280; y=0; })
  # ])

  (plain "layout" [
    (flag "empty-workspace-above-first")
    # By default focus ring and border are rendered as a solid background rectangle
    # behind windows. That is, they will show up through semitransparent windows.
    # This is because windows using client-side decorations can have an arbitrary shape.
    #
    # If you don't like that, you should uncomment `prefer-no-csd` below.
    # Niri will draw focus ring and border *around* windows that agree to omit their
    # client-side decorations.

    # You can change how the focus ring looks.
    (plain "focus-ring" [
      # Uncomment this line to disable the focus ring.
      (flag "off")

      # How many logical pixels the ring extends out from the windows.
      (leaf "width" 4)

      # Colors can be set in a variety of ways:
      # - CSS named colors: "red"
      # - RGB hex: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
      # - CSS-like notation: "rgb(255, 127, 0)", rgba(), hsl() and a few others.

      # Color of the ring on the active monitor.
      (leaf "active-color" "#7fc8ff")

      # Color of the ring on inactive monitors.
      (leaf "inactive-color" "#505050")

      # Additionally, there's a legacy RGBA syntax:
      # (leaf "active-color" [ 127 200 255 255 ])

      # You can also use gradients. They take precedence over solid colors.
      # Gradients are rendered the same as CSS linear-gradient(angle, from, to).
      # The angle is the same as in linear-gradient, and is optional,
      # defaulting to 180 (top-to-bottom gradient).
      # You can use any CSS linear-gradient tool on the web to set these up.
      #
      # (leaf "active-gradient" { from="#80c8ff"; to="#bbddff"; angle=45; })

      # You can also color the gradient relative to the entire view
      # of the workspace, rather than relative to just the window itself.
      # To do that, set relative-to="workspace-view";
      #
      # (leaf "inactive-gradient" { from="#505050"; to="#808080"; angle=45; relative-to="workspace-view"; })
    ])

    # You can also add a border. It's similar to the focus ring, but always visible.
    (plain "border" [
      # The settings are the same as for the focus ring.
      # If you enable the border, you probably want to disable the focus ring.
      # (flag "off")

      (leaf "width" 4)
      (leaf "active-color" "#ffc87f")
      (leaf "inactive-color" "#505050")

      # (leaf "active-gradient" { from="#ffbb66"; to="#ffc880"; angle=45; relative-to="workspace-view"; })
      # (leaf "inactive-gradient" { from="#505050"; to="#808080"; angle=45; relative-to="workspace-view"; })
    ])

    # You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
    (plain "preset-column-widths" [
      # Proportion sets the width as a fraction of the output width, taking gaps into account.
      # For example, you can perfectly fit four windows sized "proportion 0.25" on an output.
      # The default preset widths are 1/3, 1/2 and 2/3 of the output.
      (leaf "proportion" (1.0 / 3.0))
      (leaf "proportion" (1.0 / 2.0))
      (leaf "proportion" (2.0 / 3.0))

      # Fixed sets the width in logical pixels exactly.
      # (leaf "fixed" 1920)
    ])

    # You can change the default width of the new windows.
    (plain "default-column-width" [
      (leaf "proportion" 0.5)
    ])
    # If you leave the children empty, the windows themselves will decide their initial width.
    # (plain "default-column-width" [])

    # Set gaps around windows in logical pixels.
    (leaf "gaps" 16)

    # You can enable drop shadows for windows.
    (plain "shadow" [
      # Uncomment the next line to enable shadows.
      (flag "on")

      # By default, the shadow draws only around its window, and not behind it.
      # Uncomment this setting to make the shadow draw behind its window.
      #
      # Note that niri has no way of knowing about the CSD window corner
      # radius. It has to assume that windows have square corners, leading to
      # shadow artifacts inside the CSD rounded corners. This setting fixes
      # those artifacts.
      #
      # However, instead you may want to set prefer-no-csd and/or
      # geometry-corner-radius. Then, niri will know the corner radius and
      # draw the shadow correctly, without having to draw it behind the
      # window. These will also remove client-side shadows if the window
      # draws any.
      #
      # (draw-behind-window "on")

      # You can change how shadows look. The values below are in logical
      # pixels and match the CSS box-shadow properties.

      # Softness controls the shadow blur radius.
      (leaf "softness" 30)

      # Spread expands the shadow.
      (leaf "spread" 5)

      # Offset moves the shadow relative to the window.
      (leaf "offset" {
        x = 0;
        y = 5;
      })

      # You can also change the shadow color and opacity.
      (leaf "color" "#0007")
    ])

    # Struts shrink the area occupied by windows, similarly to layer-shell panels.
    # You can think of them as a kind of outer gaps. They are set in logical pixels.
    # Left and right struts will cause the next window to the side to always be visible.
    # Top and bottom struts will simply add outer gaps in addition to the area occupied by
    # layer-shell panels and regular gaps.
    (plain "struts" [
      (leaf "left" 64)
      (leaf "right" 64)
      # (leaf "top" 64)
      # (leaf "bottom" 64)
    ])

    # When to center a column when changing focus, options are:
    # - "never", default behavior, focusing an off-screen column will keep at the left
    #   or right edge of the screen.
    # - "on-overflow", focusing a column will center it if it doesn't fit
    #   together with the previously focused column.
    # - "always", the focused column will always be centered.
    (leaf "center-focused-column" "never")
  ])

  # Add lines like this to spawn processes at startup.
  # Note that running niri as a session supports xdg-desktop-autostart,
  # which may be more convenient to use.
  # (leaf "spawn-at-startup" [ "alacritty" "-e" "fish" ])
  # screen sharing
  (leaf "spawn-at-startup" [
    "dbus-update-activation-environment"
    "--systemd"
    "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
  ])
  (leaf "spawn-at-startup" [ "noctalia-shell" ])
  (leaf "spawn-at-startup" [ "kdeconnect-indicator" ])

  # You can override environment variables for processes spawned by niri.
  (plain "environment" [
    (leaf "QT_QPA_PLATFORM" "wayland")
    (leaf "DISPLAY" ":0") # xwayland-satellite
  ])

  (plain "cursor" [
    (flag "hide-when-typing")
    (leaf "hide-after-inactive-ms" 1000)
    # Change the theme and size of the cursor as well as set the
    # `XCURSOR_THEME` and `XCURSOR_SIZE` env variables.
    # (leaf "xcursor-theme" "default")
    # (leaf "xcursor-size" 24)
  ])

  # Uncomment this line to ask the clients to omit their client-side decorations if possible.
  # If the client will specifically ask for CSD, the request will be honored.
  # Additionally, clients will be informed that they are tiled, removing some rounded corners.
  (flag "prefer-no-csd")

  # You can change the path where screenshots are saved.
  # A ~ at the front will be expanded to the home directory.
  # The path is formatted with strftime(3) to give you the screenshot date and time.
  (leaf "screenshot-path" "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png")

  # You can also set this to null to disable saving screenshots to disk.
  # (leaf "screenshot-path" null)

  # Settings for the "Important Hotkeys" overlay.
  (plain "hotkey-overlay" [
    # Uncomment this line if you don't want to see the hotkey help at niri startup.
    (flag "skip-at-startup")
  ])

  # Animation settings.
  (plain "animations" [
    # Uncomment to turn off all animations.
    # (flag "off")

    # Slow down all animations by this factor. Values below 1 speed them up instead.
    # (leaf "slowdown" 3.0)

    # You can configure all individual animations.
    # Available settings are the same for all of them.
    # - off disables the animation.
    #
    # Niri supports two animation types: easing and spring.
    # You can set properties for only ONE of them.
    #
    # Easing has the following settings:
    # - duration-ms sets the duration of the animation in milliseconds.
    # - curve sets the easing curve. Currently, available curves
    #   are "ease-out-cubic" and "ease-out-expo".
    #
    # Spring animations work better with touchpad gestures, because they
    # take into account the velocity of your fingers as you release the swipe.
    # The parameters are less obvious and generally should be tuned
    # with trial and error. Notably, you cannot directly set the duration.
    # You can use this app to help visualize how the spring parameters
    # change the animation: https://flathub.org/apps/app.drey.Elastic
    #
    # A spring animation is configured like this:
    # - (leaf "spring" { damping-ratio=1.0; stiffness=1000; epsilon=0.0001; })
    #
    # The damping ratio goes from 0.1 to 10.0 and has the following properties:
    # - below 1.0: underdamped spring, will oscillate in the end.
    # - above 1.0: overdamped spring, won't oscillate.
    # - 1.0: critically damped spring, comes to rest in minimum possible time
    #    without oscillations.
    #
    # However, even with damping ratio = 1.0 the spring animation may oscillate
    # if "launched" with enough velocity from a touchpad swipe.
    #
    # Lower stiffness will result in a slower animation more prone to oscillation.
    #
    # Set epsilon to a lower value if the animation "jumps" in the end.
    #
    # The spring mass is hardcoded to 1.0 and cannot be changed. Instead, change
    # stiffness proportionally. E.g. increasing mass by 2x is the same as
    # decreasing stiffness by 2x.

    # Animation when switching workspaces up and down,
    # including after the touchpad gesture.
    (plain "workspace-switch" [
      # (flag "off")
      # (leaf "spring" { damping-ratio=1.0; stiffness=1000; epsilon=0.0001; })
    ])

    # All horizontal camera view movement:
    # - When a window off-screen is focused and the camera scrolls to it.
    # - When a new window appears off-screen and the camera scrolls to it.
    # - When a window resizes bigger and the camera scrolls to show it in full.
    # - And so on.
    (plain "horizontal-view-movement" [
      # (flag "off")
      # (leaf "spring" { damping-ratio=1.0; stiffness=800; epsilon=0.0001; })
    ])

    # Window opening animation. Note that this one has different defaults.
    (plain "window-open" [
      # (flag "off")
      # (leaf "duration-ms" 150)
      # (leaf "curve" "ease-out-expo")

      # Example for a slightly bouncy window opening:
      # (leaf "spring" { damping-ratio=0.8; stiffness=1000; epsilon=0.0001; })
    ])

    # Config parse error and new default config creation notification
    # open/close animation.
    (plain "config-notification-open-close" [
      # (flag "off")
      # (leaf "spring" { damping-ratio=0.6; stiffness=1000; epsilon=0.001; })
    ])
  ])

  # Window rules let you adjust behavior for individual windows.
  # They are processed in order of appearance in this file.
  # Get info by `wlrctl window list`.
  # (plain "window-rule" [
  #   # Match directives control which windows this rule will apply to.
  #   # You can match by app-id and by title.
  #   # The window must match all properties of the match directive.
  #   (leaf "match" { app-id="org.myapp.MyApp"; title="My Cool App"; })

  #   # There can be multiple match directives. A window must match any one
  #   # of the rule's match directives.
  #   #
  #   # If there are no match directives, any window will match the rule.
  #   (leaf "match" { title="Second App"; })

  #   # You can also add exclude directives which have the same properties.
  #   # If a window matches any exclude directive, it won't match this rule.
  #   #
  #   # Both app-id and title are regular expressions.
  #   # Literal nix strings can be helpful here.
  #   (leaf "exclude" { app-id=''\.unwanted\.''; })

  #   # Here are the properties that you can set on a window rule.
  #   # You can override the default column width.
  #   (plain "default-column-width" [
  #     (leaf "proportion" 0.75)
  #   ])

  #   # You can set the output that this window will initially open on.
  #   # If such an output does not exist, it will open on the currently
  #   # focused output as usual.
  #   (leaf "open-on-output" "eDP-1")

  #   # Make this window open as a maximized column.
  #   (leaf "open-maximized" true)

  #   # Make this window open fullscreen.
  #   (leaf "open-fullscreen" true)
  #   # You can also set this to false to prevent a window from opening fullscreen.
  #   # (leaf "open-fullscreen" false)
  # ])

  (plain "window-rule" [
    (leaf "clip-to-geometry" true)
    (leaf "geometry-corner-radius" 50)
  ])

  (plain "window-rule" [
    (leaf "match" { is-active = true; })
    (leaf "opacity" 1.0)
  ])

  (plain "window-rule" [
    (leaf "match" { is-active = false; })
    (leaf "opacity" 0.9)
  ])

  (plain "binds" [
    # Keys consist of modifiers separated by + signs, followed by an XKB key name
    # in the end. To find an XKB name for a particular key, you may use a program
    # like wev.
    #
    # "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
    # when running as a winit window.
    #
    # Most actions that you can bind here can also be invoked programmatically with
    # `niri msg action do-something`.

    # Mod-/, which is usually the same as Mod-?,
    # shows a list of important hotkeys.
    (plain "Mod+Slash" [ (flag "show-hotkey-overlay") ])

    (plain "Mod+L" [ (leaf "spawn" (noctalia "lockScreen lock")) ])
    (plain "Mod+W" [
      (leaf "spawn" [
        "firefox"
        "--new-window"
        "about:newtab"
      ])
    ])
    (plain "Mod+Shift+W" [
      (leaf "spawn" [
        "tor-browser"
        "--new-window"
        "about:newtab"
      ])
    ])
    (plain "Mod+T" [ (leaf "spawn" [ "wezterm" ]) ])
    (plain "Mod+E" [ (leaf "spawn" [ "thunar" ]) ])
    (plain "Mod+Space" [ (leaf "spawn" (noctalia "launcher toggle")) ])

    (plain "Mod+Escape" [
      (leaf "spawn" (noctalia "notifications dismissAll"))
    ])
    (plain "Mod+Grave" [
      (leaf "spawn" (noctalia "notifications toggleHistory"))
    ])

    # You can also use a shell:
    # (plain "Mod+T" [(leaf "spawn" [ "bash" "-c" "notify-send hello && exec alacritty" ])])

    # (plain "Mod+Tab" [ (leaf "next-window" { }) ])
    # (plain "Mod+Shift+Tab" [ (leaf "previous-window" { }) ])

    # Example volume keys mappings for PipeWire & WirePlumber.
    (plain "XF86AudioRaiseVolume" [
      (leaf "spawn" (noctalia "volume increase"))
    ])
    (plain "XF86AudioLowerVolume" [
      (leaf "spawn" (noctalia "volume decrease"))
    ])
    (plain "XF86AudioMute" [
      (leaf "spawn" (noctalia "volume muteOutput"))
    ])
    (plain "XF86AudioPlay" [
      (leaf "spawn" (noctalia "media playPause"))
    ])
    (plain "XF86AudioStop" [
      (leaf "spawn" (noctalia "media pause"))
    ])
    (plain "XF86AudioPrev" [
      (leaf "spawn" (noctalia "media previous"))
    ])
    (plain "XF86AudioNext" [
      (leaf "spawn" (noctalia "media next"))
    ])

    # Example brightness key mappings for brightnessctl.
    # You can use regular spawn with multiple arguments too (to avoid going through "sh"),
    # but you need to manually put each argument in separate "" quotes.
    # (node "XF86MonBrightnessUp" { allow-when-locked = true; } [
    #   (leaf "spawn" (noctalia "brightness increase"))
    # ])
    # (node "XF86MonBF86MonBrightnessDown" { allow-when-locked = true; } [
    #   (leaf "spawn" (noctalia "brightness decrease"))
    # ])

    (plain "Mod+Shift+XF86TouchpadToggle" [ (leaf "spawn" (noctalia "launcher toggle")) ])
    (plain "XF86Calculator" [ (leaf "spawn" (noctalia "launcher calculator")) ])
    (plain "Mod+Ctrl+Shift+Alt+Space" [ (leaf "spawn" (noctalia "launcher emoji")) ])

    (plain "Mod+O" [ (flag "toggle-overview") ])
    (plain "Mod+Q" [ (flag "close-window") ])

    (plain "Mod+Left" [ (flag "focus-column-left-or-last") ])
    (plain "Mod+Down" [ (flag "focus-window-or-workspace-down") ])
    (plain "Mod+Up" [ (flag "focus-window-or-workspace-up") ])
    (plain "Mod+Right" [ (flag "focus-column-right-or-first") ])
    (plain "Mod+D" [ (flag "focus-column-left-or-last") ])
    (plain "Mod+F" [ (flag "focus-column-right-or-first") ])

    (plain "Mod+Shift+Left" [ (flag "move-column-left") ])
    (plain "Mod+Shift+Down" [ (flag "move-window-down-or-to-workspace-down") ])
    (plain "Mod+Shift+Up" [ (flag "move-window-up-or-to-workspace-up") ])
    (plain "Mod+Shift+Right" [ (flag "move-column-right") ])
    (plain "Mod+Shift+D" [ (flag "move-column-left") ])
    (plain "Mod+Shift+F" [ (flag "move-column-right") ])

    (plain "Mod+Home" [ (flag "focus-column-first") ])
    (plain "Mod+End" [ (flag "focus-column-last") ])
    (plain "Mod+Shift+Home" [ (flag "move-column-to-first") ])
    (plain "Mod+Shift+End" [ (flag "move-column-to-last") ])

    (plain "Mod+Alt+Left" [ (flag "focus-monitor-left") ])
    (plain "Mod+Alt+Down" [ (flag "focus-monitor-down") ])
    (plain "Mod+Alt+Up" [ (flag "focus-monitor-up") ])
    (plain "Mod+Alt+Right" [ (flag "focus-monitor-right") ])
    (plain "Mod+Alt+D" [ (flag "focus-monitor-left") ])
    (plain "Mod+Alt+F" [ (flag "focus-monitor-right") ])
    # (plain "Mod+Alt+S" [ (flag "focus-monitor-up") ])
    # (plain "Mod+Alt+G" [ (flag "focus-monitor-right") ])

    (plain "Mod+Shift+Alt+Left" [ (flag "move-column-to-monitor-left") ])
    (plain "Mod+Shift+Alt+Down" [ (flag "move-column-to-monitor-down") ])
    (plain "Mod+Shift+Alt+Up" [ (flag "move-column-to-monitor-up") ])
    (plain "Mod+Shift+Alt+Right" [ (flag "move-column-to-monitor-right") ])
    # (plain "Mod+Shift+Alt+G"     [(flag "move-column-to-monitor-down")])
    # (plain "Mod+Shift+Alt+S"     [(flag "move-column-to-monitor-up")])
    (plain "Mod+Alt+S" [ (flag "move-column-to-monitor-left") ])
    (plain "Mod+Alt+G" [ (flag "move-column-to-monitor-right") ])

    # Alternatively, there are commands to move just a single window:
    # (plain "Mod+Shift+Ctrl+Left" [(flag "move-window-to-monitor-left")])
    # ...

    # And you can also move a whole workspace to another monitor:
    (plain "Mod+Shift+Alt+D" [ (flag "move-workspace-to-monitor-left") ])
    (plain "Mod+Shift+Alt+F" [ (flag "move-workspace-to-monitor-right") ])

    (plain "Mod+Page_Down" [ (flag "focus-workspace-down") ])
    (plain "Mod+Page_Up" [ (flag "focus-workspace-up") ])
    (plain "Mod+G" [ (flag "focus-workspace-down") ])
    (plain "Mod+S" [ (flag "focus-workspace-up") ])
    (plain "Mod+Shift+Page_Down" [ (flag "move-column-to-workspace-down") ])
    (plain "Mod+Shift+Page_Up" [ (flag "move-column-to-workspace-up") ])
    (plain "Mod+Shift+G" [ (flag "move-column-to-workspace-down") ])
    (plain "Mod+Shift+S" [ (flag "move-column-to-workspace-up") ])

    # Alternatively, there are commands to move just a single window:
    # (plain "Mod+Ctrl+Page_Down" [(flag "move-window-to-workspace-down")])
    # ...

    (plain "Mod+Shift+Alt+Page_Down" [ (flag "move-workspace-down") ])
    (plain "Mod+Shift+Alt+Page_Up" [ (flag "move-workspace-up") ])
    (plain "Mod+Shift+Alt+G" [ (flag "move-workspace-down") ])
    (plain "Mod+Shift+Alt+S" [ (flag "move-workspace-up") ])

    # You can refer to workspaces by index. However, keep in mind that
    # niri is a dynamic workspace system, so these commands are kind of
    # "best effort". Trying to refer to a workspace index bigger than
    # the current workspace count will instead refer to the bottommost
    # (empty) workspace.
    #
    # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
    # will all refer to the 3rd workspace.
    (plain "Mod+0" [ (leaf "focus-workspace" 1) ])
    (plain "Mod+1" [ (leaf "focus-workspace" 2) ])
    (plain "Mod+2" [ (leaf "focus-workspace" 3) ])
    (plain "Mod+3" [ (leaf "focus-workspace" 4) ])
    (plain "Mod+4" [ (leaf "focus-workspace" 5) ])
    (plain "Mod+5" [ (leaf "focus-workspace" 6) ])
    (plain "Mod+6" [ (leaf "focus-workspace" 7) ])
    (plain "Mod+7" [ (leaf "focus-workspace" 8) ])
    (plain "Mod+8" [ (leaf "focus-workspace" 9) ])
    (plain "Mod+9" [ (leaf "focus-workspace" 10) ])
    (plain "Mod+Shift+0" [ (leaf "move-column-to-workspace" 1) ])
    (plain "Mod+Shift+1" [ (leaf "move-column-to-workspace" 2) ])
    (plain "Mod+Shift+2" [ (leaf "move-column-to-workspace" 3) ])
    (plain "Mod+Shift+3" [ (leaf "move-column-to-workspace" 4) ])
    (plain "Mod+Shift+4" [ (leaf "move-column-to-workspace" 5) ])
    (plain "Mod+Shift+5" [ (leaf "move-column-to-workspace" 6) ])
    (plain "Mod+Shift+6" [ (leaf "move-column-to-workspace" 7) ])
    (plain "Mod+Shift+7" [ (leaf "move-column-to-workspace" 8) ])
    (plain "Mod+Shift+8" [ (leaf "move-column-to-workspace" 9) ])
    (plain "Mod+Shift+9" [ (leaf "move-column-to-workspace" 10) ])

    # Alternatively, there are commands to move just a single window:
    # (plain "Mod+Ctrl+1" [(leaf "move-window-to-workspace" 1)])

    (plain "Mod+Comma" [ (flag "consume-window-into-column") ])
    (plain "Mod+Period" [ (flag "expel-window-from-column") ])

    # There are also commands that consume or expel a single window to the side.
    # (plain "Mod+BracketLeft"  [(flag "consume-or-expel-window-left")])
    # (plain "Mod+BracketRight" [(flag "consume-or-expel-window-right")])

    (plain "Mod+R" [ (flag "switch-preset-column-width") ])
    (plain "Mod+A" [ (flag "maximize-column") ])
    (plain "Mod+Shift+A" [ (flag "fullscreen-window") ])
    (plain "F11" [ (flag "fullscreen-window") ])
    (plain "Mod+C" [ (flag "center-column") ])

    # Finer width adjustments.
    # This command can also:
    # * set width in pixels: "1000"
    # * adjust width in pixels: "-5" or "+5"
    # * set width as a percentage of screen width: "25%"
    # * adjust width as a percentage of screen width: "-10%" or "+10%"
    # Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
    # (leaf "set-column-width" "100") will make the column occupy 200 physical screen pixels.
    (plain "Mod+Minus" [ (leaf "set-column-width" "-10%") ])
    (plain "Mod+Equal" [ (leaf "set-column-width" "+10%") ])

    # Finer height adjustments when in column with other windows.
    (plain "Mod+Shift+Minus" [ (leaf "set-window-height" "-10%") ])
    (plain "Mod+Shift+Equal" [ (leaf "set-window-height" "+10%") ])

    # Actions to switch layouts.
    # Note: if you uncomment these, make sure you do NOT have
    # a matching layout switch hotkey configured in xkb options above.
    # Having both at once on the same hotkey will break the switching,
    # since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
    # (plain "Mod+Space"       [(leaf "switch-layout" "next")])
    # (plain "Mod+Shift+Space" [(leaf "switch-layout" "prev")])

    (plain "Print" [ (flag "screenshot") ])
    (plain "Ctrl+Print" [ (flag "screenshot-screen") ])
    (plain "Alt+Print" [ (flag "screenshot-window") ])

    # The quit action will show a confirmation dialog to avoid accidental exits.
    # If you want to skip the confirmation dialog, set the flag like so:
    # (plain "Mod+Shift+E" [(leaf "quit" { skip-confirmation=true; })])
    # (plain "Mod+Shift+E" [(flag "quit")])

    # (plain "Mod+Shift+P" [(flag "power-off-monitors")])

    # This debug bind will tint all surfaces green, unless they are being
    # directly scanned out. It's therefore useful to check if direct scanout
    # is working.
    # (plain "Mod+Shift+Ctrl+T" [(flag "toggle-debug-tint")])

    # (leaf "Mod+Apostrophe" { switch-layout = "next"; })
    # (leaf "Mod+Shift+Apostrophe" { switch-layout = "prev"; })

    (node "Mod+WheelScrollDown" { cooldown-ms = 150; } [ (flag "focus-workspace-down") ])
    (node "Mod+WheelScrollUp" { cooldown-ms = 150; } [ (flag "focus-workspace-up") ])
    (node "Mod+Shift+WheelScrollDown" { cooldown-ms = 150; } [ (flag "move-column-to-workspace-down") ])
    (node "Mod+Shift+WheelScrollUp" { cooldown-ms = 150; } [ (flag "move-column-to-workspace-up") ])

  ])

  # Set the overview wallpaper on the backdrop.
  (plain "layer-rule" [
    (leaf "match" { namespace = "^noctalia-overview*"; })
    (leaf "place-within-backdrop" true)
  ])

  (plain "debug" [
    # Allows notification actions and window activation from Noctalia.
    (flag "honor-xdg-activation-with-invalid-serial")
  ])
]
