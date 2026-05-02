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
      prompts = {
        "kimi-key" = { };
        "minimax-key" = { };
      };
      files = {
        "kimi-key".secret = true;
        "minimax-key".secret = true;
      };
    };
  };

  home-manager.users.${user} =
    { ... }:
    {
      _class = "homeManager";

      programs.opencode = {
        enable = true;
        tui.theme = "mocha";
        themes.mocha = {
          defs = {
            base = "#3B3228";
            surface0 = "#534636";
            surface1 = "#645240";
            overlay0 = "#7e705a";
            subtext0 = "#b8afad";
            text = "#d0c8c6";
            rosewater = "#e9e1dd";
            lavender = "#f5eeeb";
            red = "#cb6077";
            peach = "#d28b71";
            yellow = "#f4bc87";
            green = "#beb55b";
            teal = "#7bbda4";
            blue = "#8ab3b5";
            mauve = "#a89bb9";
            flamingo = "#bb9584";
          };
          theme = let d = name: { dark = name; light = name; }; in {
            primary = d "blue";
            secondary = d "mauve";
            accent = d "teal";
            error = d "red";
            warning = d "peach";
            success = d "green";
            info = d "blue";
            # user input: bright text
            text = d "lavender";
            textMuted = d "overlay0";
            background = d "base";
            backgroundPanel = d "surface0";
            backgroundElement = d "surface0";
            border = d "surface1";
            borderActive = d "overlay0";
            borderSubtle = d "surface1";
            diffAdded = d "green";
            diffRemoved = d "red";
            diffContext = d "overlay0";
            diffHunkHeader = d "overlay0";
            diffHighlightAdded = d "green";
            diffHighlightRemoved = d "red";
            diffAddedBg = d "surface0";
            diffRemovedBg = d "surface0";
            diffContextBg = d "surface0";
            diffLineNumber = d "overlay0";
            diffAddedLineNumberBg = d "surface0";
            diffRemovedLineNumberBg = d "surface0";
            # AI responses: softer, distinct color
            markdownText = d "subtext0";
            markdownHeading = d "blue";
            markdownLink = d "mauve";
            markdownLinkText = d "teal";
            markdownCode = d "green";
            markdownBlockQuote = d "overlay0";
            markdownEmph = d "peach";
            markdownStrong = d "yellow";
            markdownHorizontalRule = d "overlay0";
            markdownListItem = d "blue";
            markdownListEnumeration = d "teal";
            markdownImage = d "mauve";
            markdownImageText = d "teal";
            markdownCodeBlock = d "text";
            syntaxComment = d "overlay0";
            syntaxKeyword = d "mauve";
            syntaxFunction = d "blue";
            syntaxVariable = d "teal";
            syntaxString = d "green";
            syntaxNumber = d "peach";
            syntaxType = d "teal";
            syntaxOperator = d "mauve";
            syntaxPunctuation = d "text";
          };
        };
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
              apiKey = "{file:${config.vars.generators."prompted".files."minimax-key".path}}";
              # baseURL = "https://api.kimi.com/coding/";
              # apiKey = "{file:${config.vars.generators."prompted".files."kimi-key".path}}";
            };
          };
          # mcp.deepwiki = {
          #   type = "remote";
          #   url = "https://mcp.deepwiki.com/mcp";
          # };
          plugin = [
            "file://${../home/opencode-notify.ts}"
            "file://${../home/opencode-tts.ts}"
            "opencode-background"
            "opencode-background-agents"
            "opencode-direnv"
            "opencode-mystatus"
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
