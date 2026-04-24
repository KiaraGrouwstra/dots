{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "media-play-pause";
  runtimeInputs = [ pkgs.playerctl pkgs.dbus pkgs.procps ];
  text = ''
    # Usage: media-play-pause [pause|play|play-pause]
    # Default (no argument) toggles the most appropriate player.
    # pause: pause whatever is currently playing, saving it to state.
    # play:  resume only the player saved in state (does nothing if none).
    MODE="''${1:-play-pause}"

    # Returns 0 if the player is an AVRCP Bluetooth player proxied by
    # mpris-proxy, 1 otherwise.
    is_avrcp() {
      local unique pid comm
      unique=$(dbus-send --session --print-reply \
        --dest=org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus.GetNameOwner \
        "string:org.mpris.MediaPlayer2.$1" 2>/dev/null \
        | awk -F'"' '/string "/{print $2; exit}')
      [ -z "$unique" ] && return 1
      pid=$(dbus-send --session --print-reply \
        --dest=org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus.GetConnectionUnixProcessID \
        "string:$unique" 2>/dev/null \
        | awk '/uint32/{print $2; exit}')
      [ -z "$pid" ] && return 1
      comm=$(ps -p "$pid" -o comm= 2>/dev/null || echo "")
      [ "$comm" = "mpris-proxy" ]
    }

    state_file="''${XDG_RUNTIME_DIR:-/tmp}/media-play-pause.last"

    control() {
      echo "$1" > "$state_file"
      playerctl -p "$1" play-pause
    }

    all_players=$(playerctl -l 2>/dev/null || true)

    if [ "$MODE" = "play" ]; then
      # Resume only the player we last controlled, if it is still paused.
      if [ -f "$state_file" ]; then
        last=$(cat "$state_file")
        if playerctl -l 2>/dev/null | grep -qxF "$last"; then
          if [ "$(playerctl -p "$last" status 2>/dev/null)" = "Paused" ]; then
            control "$last"
          fi
        fi
      fi
      exit 0
    fi

    if [ "$MODE" = "pause" ]; then
      # Pause whichever player is currently playing (local first, then KDE Connect / AVRCP).
      # Exits 0 if a player was paused, 1 otherwise — lets callers tell whether
      # they should later trigger a matching resume.
      paused_player=""
      while IFS= read -r p; do
        case "$p" in kdeconnect.*) continue ;; esac
        is_avrcp "$p" && continue
        if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
          control "$p"
          paused_player="$p"
          break
        fi
      done <<< "$all_players"
      if [ -z "$paused_player" ]; then
        while IFS= read -r p; do
          case "$p" in kdeconnect.*) ;; *) is_avrcp "$p" || continue ;; esac
          if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
            control "$p"
            paused_player="$p"
            break
          fi
        done <<< "$all_players"
      fi
      # Wait until the player reports it is no longer Playing (timeout 3s).
      if [ -n "$paused_player" ]; then
        i=0
        while [ $i -lt 10 ]; do
          [ "$(playerctl -p "$paused_player" status 2>/dev/null)" != "Playing" ] && break
          sleep 0.3
          i=$((i + 1))
        done
        exit 0
      fi
      exit 1
    fi

    # play-pause: toggle using all phases.

    # Phase 1: local player that is Playing
    while IFS= read -r p; do
      case "$p" in kdeconnect.*) continue ;; esac
      is_avrcp "$p" && continue
      if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
        control "$p"
        exit 0
      fi
    done <<< "$all_players"

    # Phase 2: KDE Connect or AVRCP player that is Playing
    while IFS= read -r p; do
      case "$p" in kdeconnect.*) ;; *) is_avrcp "$p" || continue ;; esac
      if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
        control "$p"
        exit 0
      fi
    done <<< "$all_players"

    # Phase 3: resume whichever player we last controlled, if still paused
    if [ -f "$state_file" ]; then
      last=$(cat "$state_file")
      if playerctl -l 2>/dev/null | grep -qxF "$last"; then
        if [ "$(playerctl -p "$last" status 2>/dev/null)" = "Paused" ]; then
          control "$last"
          exit 0
        fi
      fi
    fi

    # Phase 4: any local player that is Paused
    while IFS= read -r p; do
      case "$p" in kdeconnect.*) continue ;; esac
      is_avrcp "$p" && continue
      if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Paused" ]; then
        control "$p"
        exit 0
      fi
    done <<< "$all_players"

    # Phase 5: any KDE Connect or AVRCP player that is Paused
    while IFS= read -r p; do
      case "$p" in kdeconnect.*) ;; *) is_avrcp "$p" || continue ;; esac
      if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Paused" ]; then
        control "$p"
        exit 0
      fi
    done <<< "$all_players"
  '';
}
