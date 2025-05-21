{
  user,
  ...
}:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "cinereal";
    userEmail = "cinereal@riseup.net";
    delta = {
      enable = true;
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
    aliases = {
      # commit staged changes to main branch
      main = "!export BRANCH=$(git rev-parse --abbrev-ref HEAD) && git stash --keep-index --include-untracked && git switch main && git commit && git push && git switch $BRANCH && git rebase main && git push --force && git stash pop";
    };

    extraConfig = {
      core.editor = "$EDITOR";
      init.defaultBranch = "main";
      advice.objectNameWarning = false;
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "current";
      branch.autoSetupRebase = "always";
      branch.autoSetupMerge = "simple";
      checkout.defaultRemote = "origin";
      remote.pushDefault = user;
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };
}
