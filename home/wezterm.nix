{
  config,
  inputs,
  system,
  ...
}:
{
  programs.wezterm = {
    enable = true;
    # package = inputs.wezterm.packages.${system}.default;
    extraConfig =
      # lua
      ''
         local act = wezterm.action
         wezterm.add_to_config_reload_watch_list("/home/kiara/.config/wezterm/theme.toml");

        -- https://github.com/wez/wezterm/issues/6446#issuecomment-2568005371
         local function action_unless_fullscreen(action, key_or_key_spec)
           if type(key_or_key_spec) == "string" then
             key_or_key_spec = { key = key_or_key_spec }
           end
           local key_spec = {
             key = key_or_key_spec.key,
             mods = key_or_key_spec.mods or "NONE",
           }
           return wezterm.action_callback(function(win, pane)
             if pane:is_alt_screen_active() then
               -- a program is full screen, passthrough
               win:perform_action(act.SendKey(key_spec), pane)
             else
               -- do the action
               win:perform_action(action, pane)
             end
           end)
         end

         return {
             hide_tab_bar_if_only_one_tab = true,
             window_close_confirmation = "NeverPrompt",
             enable_kitty_keyboard = true,
             set_environment_variables = {
                 TERM = "wezterm"
             },
             font_size = 10.0,
             -- color_scheme_dirs = {"/home/kiara/.config/wezterm"},
             -- color_scheme = "theme",
             color_scheme = 'Earthsong',
             keys = {
                 {
                     key = "0",
                     mods = "ALT",
                     action = act.ResetFontSize
                 },
                 {
                     key = "1",
                     mods = "ALT",
                     action = act {ActivateTab = 0}
                 },
                 {
                     key = "2",
                     mods = "ALT",
                     action = act {ActivateTab = 1}
                 },
                 {
                     key = "3",
                     mods = "ALT",
                     action = act {ActivateTab = 2}
                 },
                 {
                     key = "4",
                     mods = "ALT",
                     action = act {ActivateTab = 3}
                 },
                 {
                     key = "5",
                     mods = "ALT",
                     action = act {ActivateTab = 4}
                 },
                 {
                     key = "6",
                     mods = "ALT",
                     action = act {ActivateTab = 5}
                 },
                 {
                     key = "7",
                     mods = "ALT",
                     action = act {ActivateTab = 6}
                 },
                 {
                     key = "8",
                     mods = "ALT",
                     action = act {ActivateTab = 7}
                 },
                 {
                     key = "9",
                     mods = "ALT",
                     action = act {ActivateTab = -1}
                 },
                 {
                     key = "0",
                     mods = "ALT",
                     action = act.ResetFontSize
                 },
                 {
                     key = "!",
                     mods = "ALT",
                     action = act {ActivateTab = 0}
                 },
                 {
                     key = "@",
                     mods = "ALT",
                     action = act {ActivateTab = 1}
                 },
                 {
                     key = "#",
                     mods = "ALT",
                     action = act {ActivateTab = 2}
                 },
                 {
                     key = "$",
                     mods = "ALT",
                     action = act {ActivateTab = 3}
                 },
                 {
                     key = "%",
                     mods = "ALT",
                     action = act {ActivateTab = 4}
                 },
                 {
                     key = "^",
                     mods = "ALT",
                     action = act {ActivateTab = 5}
                 },
                 {
                     key = "&",
                     mods = "ALT",
                     action = act {ActivateTab = 6}
                 },
                 {
                     key = "*",
                     mods = "ALT",
                     action = act {ActivateTab = 7}
                 },
                 {
                     key = "(",
                     mods = "ALT",
                     action = act {ActivateTab = -1}
                 },
                 {
                     key = ")",
                     mods = "ALT",
                     action = act.ResetFontSize
                 },
                 {
                     key = "-",
                     mods = "ALT",
                     action = act.DecreaseFontSize
                 },
                 -- {
                 --    key = '"',
                 --    mods = 'ALT',
                 --    action = act{SplitVertical = {domain="CurrentPaneDomain"}},
                 -- },
                 -- {
                 --    key = '[',
                 --    mods = 'ALT',
                 --    action = act{ActivateTabRelative = -1 },
                 -- },
                 -- {
                 --    key = ']',
                 --    mods = 'ALT',
                 --    action = act{ActivateTabRelative = 1 },
                 -- },
                 -- {
                 --    key = '%',
                 --    mods = 'ALT',
                 --    action = act{SplitHorizontal = {domain="CurrentPaneDomain"}},
                 -- },
                 {
                     key = "=",
                     mods = "ALT",
                     action = act.IncreaseFontSize
                 },
                 {
                     key = "c",
                     mods = "ALT",
                     action = act {CopyTo = "Clipboard"}
                 },
                 -- {
                 --    key = 'DownArrow',
                 --    mods = 'ALT',
                 --    action = act{ActivatePaneDirection = "Down" },
                 -- },
                 -- {
                 --    key = 'LeftArrow',
                 --    mods = 'ALT',
                 --    action = act{ActivatePaneDirection = "Left"},
                 -- },
                 -- {
                 --    key = 'RightArrow',
                 --    mods = 'ALT',
                 --    action = act{ActivatePaneDirection = "Right"},
                 -- },
                 -- {
                 --    key = 'UpArrow',
                 --    mods = 'ALT',
                 --    action = act{ActivatePaneDirection = "Up"},
                 -- },
                 -- {
                 --    key = -- 'DownArrow',
                 --    mods =--  'ALT|SHIFT',
                 --    action--  = act{AdjustPaneSize = { "Down", 1 }},
                 -- },
                 -- {
                 --    key = -- 'LeftArrow',
                 --    mods =--  'ALT|SHIFT',
                 --    action--  = act{AdjustPaneSize = {"Left",1}},
                 -- },
                 -- {
                 --    key = -- 'RightArrow',
                 --    mods =--  'ALT|SHIFT',
                 --    action--  = act{AdjustPaneSize = {"Right",1}},
                 -- },
                 -- {
                 --    key = -- 'UpArrow',
                 --    mods =--  'ALT|SHIFT',
                 --    action--  = act{AdjustPaneSize = {"Up",1}},
                 -- },
                 {
                     key = "g",
                     mods = "ALT|SHIFT",
                     action = act {Search = {CaseSensitiveString = ""}}
                 },
                 {
                     key = "f",
                     mods = "ALT",
                     action = act {ActivateTabRelative = 1}
                 },
                 {
                    key = 'j',
                    mods = 'ALT',
                    action = action_unless_fullscreen(act.ScrollByPage(1.0), 'PageDown'),
                 },
                 {
                     key = "f",
                     mods = "ALT|SHIFT",
                     action = act {MoveTabRelative = 1}
                 },
                 {
                     key = "d",
                     mods = "ALT",
                     action = act {ActivateTabRelative = -1}
                 },
                 {
                    key = 'k',
                    mods = 'ALT',
                    action = action_unless_fullscreen(act.ScrollByPage(-1.0), 'PageUp'),
                 },
                 {
                     key = "d",
                     mods = "ALT|SHIFT",
                     action = act {MoveTabRelative = -1}
                 },
                 -- {
                 --    key = 'l',
                 --    mods = 'ALT',
                 --    action = act.ShowDebugOverlay,
                 -- },
                 -- {
                 --    key = 'm',
                 --    mods = 'ALT',
                 --    action = act.Hide,
                 -- },
                 {
                     key = 'o',
                     mods = "ALT",
                     action = act.SpawnWindow
                 },
                 {
                     key = "Comma",
                     mods = "ALT",
                     action = act.ActivateCommandPalette
                 },
                 -- {
                 --    key = 'r',
                 --    mods = 'ALT',
                 --    action = act.ReloadConfiguration,
                 -- },
                 {
                     key = "s",
                     mods = "ALT|SHIFT",
                     action = act.QuickSelect
                 },
                 {
                     key = "t",
                     mods = "ALT",
                     action = act {SpawnTab = "CurrentPaneDomain"}
                 },
                 -- {
                 --    key = "t",
                 --    mods = 'ALT|SHIFT',
                 --    action = act{SpawnTab = "DefaultDomain"},
                 -- },
                 {
                     key = "i",
                     mods = "ALT",
                     action = act.CharSelect
                 },
                 {
                     key = "v",
                     mods = "ALT",
                     action = act {PasteFrom = "Clipboard"}
                 },
                 {
                     key = "q",
                     mods = "ALT",
                     action = act {CloseCurrentTab = {confirm = false}}
                 },
                 {
                     key = "x",
                     mods = "ALT",
                     action = act.ActivateCopyMode
                 }
                 -- {
                 --    key = 'Semicolon',
                 --    mods = 'ALT',
                 --    action = act.TogglePaneZoomState,
                 -- },
             }
         }
      '';
  };
}
