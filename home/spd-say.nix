{ pkgs, ... }:
let
  media-play-pause = pkgs.callPackage ./media-play-pause.nix { };
in
# Wrapper around spd-say that pauses media during speech and resumes after.
# Shows a notification with a Stop button to cancel playback.
# Only resumes media if something was actually playing when we paused
# (avoids interfering with dictation's own media-pause lifecycle).
pkgs.writeShellScriptBin "spd-say" ''
  # Skip TTS when muted.
  if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
     | ${pkgs.gnugrep}/bin/grep -q MUTED; then
    exit 0
  fi

  # Skip TTS when a WebRTC call (or any mic capture) is active.
  if ${pkgs.pipewire}/bin/pw-dump 2>/dev/null \
     | ${pkgs.gnugrep}/bin/grep -q '"media.class".*"Stream/Input/Audio"'; then
    exit 0
  fi

  # Buffer stdin before backgrounding (backgrounded processes lose stdin).
  input=""
  if [ ! -t 0 ]; then
    input=$(cat)
  fi

  should_resume=0
  resume() {
    [ "$should_resume" = "1" ] && \
      ${media-play-pause}/bin/media-play-pause play </dev/null >/dev/null 2>&1 || true
  }
  trap resume EXIT

  # `media-play-pause pause` exits 0 iff it actually paused a player;
  # using its exit code avoids a race between a pre-check and the pause call.
  if ${media-play-pause}/bin/media-play-pause pause </dev/null; then
    should_resume=1
  fi

  if [ -n "$input" ]; then
    echo "$input" | ${pkgs.speechd}/bin/spd-say -w "$@" &
  else
    ${pkgs.speechd}/bin/spd-say -w "$@" &
  fi
  spd_pid=$!

  # Offer a Stop button via notification. Uses real libnotify to bypass
  # our notify-send TTS wrapper and avoid recursion.
  (
    action=$(${pkgs.libnotify}/bin/notify-send -t 0 -A "stop=Stop" "Speaking" 2>/dev/null || true)
    if [ "$action" = "stop" ]; then
      ${pkgs.speechd}/bin/spd-say -C
      kill "$spd_pid" 2>/dev/null
    fi
  ) &
  notify_pid=$!

  wait "$spd_pid" 2>/dev/null

  # Dismiss notification if speech ended naturally.
  kill "$notify_pid" 2>/dev/null
  wait "$notify_pid" 2>/dev/null
''
