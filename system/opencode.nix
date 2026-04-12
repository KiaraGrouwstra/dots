{
  config,
  sources,
  user,
  ...
}:
{
  _class = "nixos";

  vars.generators = {
    "prompted" = {
      prompts."minimax-key" = { };
      files."minimax-key".secret = true;
    };
  };

  home-manager.users.${user} =
    { ... }:
    {
      _class = "homeManager";

      programs.opencode = {
        enable = true;
        # web.enable = true;
        skills = {
          ci = "/home/kiara/.claude/skills/ci";
          implement = "/home/kiara/.claude/skills/implement";
          listen = "/home/kiara/.claude/skills/listen";
          researching-with-deepwiki = "${sources.marketplace}/skills/asmayaseen/researching-with-deepwiki";
        };
        settings = {
          # model = "anthropic/claude-opus-4-6";
          # small_model = "anthropic/claude-sonnet-4-6";
          model = "minimax/MiniMax-M2.7";
          small_model = "minimax/MiniMax-M2.7";
          autoupdate = false;
          snapshot = true;
          share = "manual";
          permission = "allow";
          provider.minimax = {
            name = "MiniMax";
            models."MiniMax-M2.7" = {
              name = "MiniMax M2.7";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              limit = {
                context = 1000000;
                output = 131072;
              };
              cost = {
                input = 1;
                output = 4;
              };
            };
            options = {
              baseURL = "https://api.minimax.io/anthropic/v1";
              # apiKey = "\${MINIMAX_API_KEY}";
              apiKey = "{file:${config.vars.generators."prompted".files."minimax-key".path}}";
            };
          };
          mcp.deepwiki = {
            type = "remote";
            url = "https://mcp.deepwiki.com/mcp";
          };
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
    };
}
