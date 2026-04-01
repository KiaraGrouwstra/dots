{ pkgs, sources, ... }:
let
  model = sources."whisper-base";

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      whisper-cpp
      wtype
      alsa-utils
    ];
    text = ''
      PIDFILE=/tmp/dictate.pid
      WAVFILE=/tmp/dictate.wav
      LANG_FLAG=""
      [ -n "''${1:-}" ] && LANG_FLAG="-l $1"

      if [ -f "$PIDFILE" ]; then
        # Stop recording
        kill "$(cat "$PIDFILE")" 2>/dev/null || true
        rm "$PIDFILE"
        sleep 0.2
        notify-send "dictate" "Transcribing…" -t 4000
        # shellcheck disable=SC2086
        whisper-cli \
          -m ${model} \
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
      else
        # Use real notify-send (not the TTS wrapper) so the announcement
        # isn't picked up by the microphone recording that follows.
        ${pkgs.libnotify}/bin/notify-send "dictate" "Listening…" -t 60000
        sleep 1
        arecord -f S16_LE -r 16000 -c 1 -t wav "$WAVFILE" &
        echo $! > "$PIDFILE"
      fi
    '';
  };
in
{
  _class = "homeManager";
  home.packages = [ dictate ];
}
