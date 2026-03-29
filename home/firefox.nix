{ pkgs, ... }:
let
  # wrapFirefox accepts extraPrefs as a string appended to mozilla.cfg.
  # The nixpkgs build already writes the required first-line comment, so our
  # JS can start immediately without worrying about that constraint.
  tabSwitchJS = ''
    (function () {
      function attachKeys(win) {
        win.addEventListener(
          "keydown",
          function (e) {
            // Skip when typing in any editable element (URL bar, inputs, etc.)
            const tag = e.target?.tagName?.toLowerCase();
            if (
              tag === "input" ||
              tag === "textarea" ||
              e.target?.isContentEditable
            )
              return;

            if (e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
              if (e.key === "j") {
                win.gBrowser.tabContainer.advanceSelectedTab(1, true);
                e.preventDefault();
              } else if (e.key === "k") {
                win.gBrowser.tabContainer.advanceSelectedTab(-1, true);
                e.preventDefault();
              }
            }
          },
          true // capture phase — fires before page content handlers
        );
      }

      Services.obs.addObserver(
        {
          observe(subject) {
            const win = subject;
            win.addEventListener(
              "load",
              function () {
                if (
                  win.document.documentElement.getAttribute("windowtype") !==
                  "navigator:browser"
                )
                  return;
                attachKeys(win);
              },
              { once: true }
            );
          },
        },
        "domwindowopened"
      );
    })();
  '';

  firefoxWithConfig = pkgs.firefox.override { extraPrefs = tabSwitchJS; };
in
{
  _class = "homeManager";

  programs.firefox = {
    enable = true;
    package = firefoxWithConfig;
    nativeMessagingHosts = [ pkgs.keepassxc ];
    profiles.default = {
      settings = {
        "media.webspeech.synth.enabled" = true;
        "narrate.voice" = "automatic";
      };
    };
  };
}
