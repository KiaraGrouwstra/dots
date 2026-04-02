{ pkgs, ... }:
let
  # Wrapper around notify-send that also speaks the notification via spd-say.
  # Parses notify-send's SUMMARY [BODY] positional args, skipping options.
  notify-send = pkgs.writeShellScriptBin "notify-send" ''
    summary=""
    body=""
    skip_next=0
    for arg in "$@"; do
      if [ "$skip_next" = "1" ]; then
        skip_next=0
        continue
      fi
      case "$arg" in
        -u|-t|-a|-i|-c|-h|-r|-A|--urgency|--expire-time|--app-name|--icon|--category|--hint|--replace-id|--action)
          skip_next=1 ;;
        --urgency=*|--expire-time=*|--app-name=*|--icon=*|--category=*|--hint=*|--replace-id=*|--action=*)
          ;;
        -*)
          ;;
        *)
          if [ -z "$summary" ]; then
            summary="$arg"
          elif [ -z "$body" ]; then
            body="$arg"
          fi
          ;;
      esac
    done

    if [ -z "$NOTIFY_NO_TTS" ]; then
      if [ -n "$body" ]; then
        ${pkgs.speechd}/bin/spd-say -i -30 "$summary: $body" &
      elif [ -n "$summary" ]; then
        ${pkgs.speechd}/bin/spd-say -i -30 "$summary" &
      fi
    fi

    exec ${pkgs.libnotify}/bin/notify-send "$@"
  '';
in
{
  _class = "homeManager";
  home.packages = [ notify-send ];
}
