{
  user,
  ...
}:
{
  _class = "homeManager";

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-decoration-style = "none";
        file-style = "bold yellow ul";
      };
      features = "decorations";
      whitespace-error-style = "22 reverse";
    };
  };

  programs.git = {
    enable = true;
    signing.format = null;
    lfs.enable = true;
    settings = {
      user.name = "cinereal";
      user.email = "cinereal@riseup.net";
      alias = {
        # commit staged changes to main branch
        main = "!export BRANCH=$(git rev-parse --abbrev-ref HEAD) && git stash --keep-index --include-untracked && git switch main && git commit && git push && git switch $BRANCH && git rebase main && git push --force && git stash pop";
      };
      core.editor = "$EDITOR";
      init.defaultBranch = "main";
      advice.objectNameWarning = false;
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "current";
      branch.autoSetupRebase = "always";
      branch.autoSetupMerge = "simple";
      checkout.defaultRemote = "origin";
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
    ignores = [
      "**/.claude/settings.local.json"
      "CLAUDE.md"
    ];
  };
}
