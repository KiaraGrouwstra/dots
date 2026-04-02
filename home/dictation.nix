{ pkgs, sources, ... }:
let
  modelEn = sources."whisper-base-en";

  modelNl = sources."whisper-medium-q5";

  modelVoxtral = sources."voxtral-mini-q4km";

  modelVoxtralMmproj = sources."voxtral-mini-mmproj";

  whisper-cpp-rocm = pkgs.whisper-cpp.override {
    rocmSupport = true;
    rocmPackages = pkgs.rocmPackages;
    rocmGpuTargets = "gfx90c";
  };

  llama-cpp-rocm = pkgs.llama-cpp.override {
    rocmSupport = true;
    rocmPackages = pkgs.rocmPackages;
    rocmGpuTargets = [ "gfx90c" ];
  };

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      whisper-cpp-rocm
      llama-cpp-rocm
      wtype
      alsa-utils
      (pkgs.callPackage ./media-play-pause.nix { })
    ];
    text = ''
      PIDFILE=/tmp/dictate.pid
      LOCKFILE=/tmp/dictate.lock
      WAVFILE=/tmp/dictate.wav
      DICTATE_LANG="''${1:-en}"
      LANG_FLAG="-l $DICTATE_LANG"
      case "$DICTATE_LANG" in
        en) MODEL="${modelEn}" ;;
        *)  MODEL="${modelNl}" ;;
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
        if [ "$DICTATE_LANG" = "nl" ]; then
          text=$(llama-mtmd-cli \
            -m "${modelVoxtral}" \
            --mmproj "${modelVoxtralMmproj}" \
            --audio "$WAVFILE" \
            -p "Transcribe this audio verbatim. Output only the transcription, nothing else." \
            --temp 0 \
            -ngl 99 \
            2>/dev/null | tr -d '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [ -n "$text" ] && wtype "$text"
        else
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
        fi
        rm -f "$WAVFILE"
        media-play-pause play
      else
        # No live recording — clean up any stale state from a previous crash.
        rm -f "$PIDFILE" "$WAVFILE"
        media-play-pause pause
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
