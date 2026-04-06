{
  _class = "homeManager";

  programs.opencode = {
    enable = true;
    tui.theme = "system";
    # web.enable = true;
    settings = {
      model = "anthropic/claude-opus-4-6";
      small_model = "anthropic/claude-sonnet-4-6";
      autoupdate = false;
      snapshot = true;
      share = "manual";
      plugin = [
        "opencode-background"
        "opencode-background-agents"
        "opencode-direnv"
        "opencode-mystatus"
        "opencode-notificator"
        "opencode-shell-strategy"
        "opencode-supermemory"
        "opencode-talk"
        "opencode-vibeguard"
        "opencode-worktree"
      ];
    };
  };
}
