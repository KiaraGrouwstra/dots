{ pkgs, sources, ... }:
let
  modelEn = sources."whisper-base-en";

  whisper-cpp-rocm = pkgs.whisper-cpp.override {
    rocmSupport = true;
    rocmPackages = pkgs.rocmPackages;
    rocmGpuTargets = "gfx90c";
  };

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      whisper-cpp-rocm
      wtype
      alsa-utils
      wireplumber
      pipewire
      (pkgs.callPackage ./media-play-pause.nix { })
    ];
    text = ''
      using_headphones() {
        local api dev_id route
        api=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/device.api/{print $2}')
        [ "$api" = "bluez5" ] && return 0
        dev_id=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/device.id/{print $2}')
        [ -z "$dev_id" ] && return 1
        route=$(pw-cli enum-params "$dev_id" Route 2>/dev/null \
          | grep -A2 "Direction:Output" | grep String | awk -F'"' '{print $2}')
        case "$route" in *headphone*) return 0 ;; esac
        return 1
      }

      PIDFILE=/tmp/dictate.pid
      LOCKFILE=/tmp/dictate.lock
      WAVFILE=/tmp/dictate.wav
      DICTATE_LANG="''${1:-en}"
      LANG_FLAG="-l $DICTATE_LANG"
      case "$DICTATE_LANG" in
        en) MODEL="${modelEn}" ;;
      esac

      # Guard only the state-check/toggle window; release as soon as state is committed.
      exec 9>"$LOCKFILE"
      flock -n 9 || exit 0

      if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        # arecord is live — stop it and release the lock so the key works again
        # immediately (whisper can take a while).
        kill "$(cat "$PIDFILE")" 2>/dev/null || true
        rm "$PIDFILE"
        flock -u 9
        sleep 0.2
        notify-send "dictate" "Transcribing…" -t 4000
        # shellcheck disable=SC2086
        whisper-cli \
          -m "$MODEL" \
          -otxt \
          -of /tmp/dictate \
          -nt \
          $LANG_FLAG \
          "$WAVFILE" 2>/dev/null
        if [ -f /tmp/dictate.txt ]; then
          text=$(grep -v '^\[' /tmp/dictate.txt | tr -d '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
          [ -n "$text" ] && wtype "$text"
          rm /tmp/dictate.txt
        fi
        rm -f "$WAVFILE"
        using_headphones || media-play-pause play
      else
        # No live recording — clean up any stale state from a previous crash.
        rm -f "$PIDFILE" "$WAVFILE"
        using_headphones || media-play-pause pause
        NOTIFY_NO_TTS=1 notify-send "dictate" "Listening…" -t 60000
        arecord -f S16_LE -r 16000 -c 1 -t wav "$WAVFILE" &
        echo $! > "$PIDFILE"
        # Lock no longer needed — PIDFILE is written, state is committed.
        flock -u 9
      fi
    '';
  };
in
{
  _class = "homeManager";
  home.packages = [ dictate ];
}
