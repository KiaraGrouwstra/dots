{ pkgs, ... }:
let
  media-play-pause = pkgs.callPackage ./media-play-pause.nix { };
in
# Wrapper around spd-say that pauses media during speech and resumes after.
# Shows a notification with a Stop button to cancel playback.
# Only resumes media if something was actually playing when we paused
# (avoids interfering with dictation's own media-pause lifecycle).
pkgs.writeShellScriptBin "spd-say" ''
  # Skip TTS when a WebRTC call (or any mic capture) is active.
  if ${pkgs.pipewire}/bin/pw-dump 2>/dev/null \
     | ${pkgs.gnugrep}/bin/grep -q '"media.class".*"Stream/Input/Audio"'; then
    exit 0
  fi

  should_resume=0
  if ${pkgs.playerctl}/bin/playerctl -a status 2>/dev/null | grep -q "Playing"; then
    ${media-play-pause}/bin/media-play-pause pause
    should_resume=1
  fi

  ${pkgs.speechd}/bin/spd-say -w "$@" &
  spd_pid=$!

  # Offer a Stop button via notification. Uses real libnotify to bypass
  # our notify-send TTS wrapper and avoid recursion.
  (
    action=$(${pkgs.libnotify}/bin/notify-send -t 0 -A "stop=Stop" "Speaking" 2>/dev/null || true)
    if [ "$action" = "stop" ]; then
      kill "$spd_pid" 2>/dev/null
    fi
  ) &
  notify_pid=$!

  wait "$spd_pid" 2>/dev/null

  # Dismiss notification if speech ended naturally.
  kill "$notify_pid" 2>/dev/null
  wait "$notify_pid" 2>/dev/null

  if [ "$should_resume" = "1" ]; then
    ${media-play-pause}/bin/media-play-pause play
  fi
''
