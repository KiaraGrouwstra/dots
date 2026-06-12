# speech-dispatcher (TTS). Finix has no services.speechd module, so we write the
# config to /etc and run the daemon as a finit service. The home-level spd-say
# wrapper + tts/dictation scripts then work unchanged.
{
  pkgs,
  sources,
  ...
}:
let
  voicesDir = pkgs.runCommand "piper-voices" { } ''
    mkdir -p $out
    cp ${sources."piper-amy-onnx"} $out/en_US-amy-medium.onnx
    cp ${sources."piper-amy-json"} $out/en_US-amy-medium.onnx.json
    cp ${sources."piper-pim-onnx"} $out/nl_NL-pim-medium.onnx
    cp ${sources."piper-pim-json"} $out/nl_NL-pim-medium.onnx.json
  '';

  speechdConf = pkgs.writeText "speechd.conf" ''
    LogLevel  3
    LogDir  "default"
    DefaultVolume 30
    SymbolsPreproc "char"
    AddModule "piper-generic" "sd_generic" "piper-generic.conf"
    DefaultModule piper-generic
  '';

  piperModuleConf = pkgs.writeText "piper-generic.conf" ''
    GenericExecuteSynth \
    "printf %s \'$DATA\' | ${pkgs.piper-tts}/bin/piper --model ${voicesDir}/$VOICE.onnx --output-raw | ${pkgs.sox}/bin/sox -t raw -r 22050 -e signed -b 16 -c 1 - -t raw -r 22050 -e signed -b 16 -c 1 - tempo 2.0 | ${pkgs.pipewire}/bin/pw-play --raw --volume 0.3 --rate 22050 --format s16 --channels 1 -"

    GenericCmdDependency "${pkgs.piper-tts}/bin/piper"
    GenericCmdDependency "${pkgs.sox}/bin/sox"
    GenericCmdDependency "${pkgs.pipewire}/bin/pw-play"

    GenericPunctNone ""
    GenericPunctSome ""
    GenericPunctMost ""
    GenericPunctAll ""

    AddVoice "en" "FEMALE1" "en_US-amy-medium"
    AddVoice "nl" "MALE1" "nl_NL-pim-medium"
    DefaultVoice "en_US-amy-medium"
  '';

  speechdConfDir = pkgs.runCommand "speechd-config" { } ''
    mkdir -p $out/modules
    cp ${speechdConf} $out/speechd.conf
    cp ${piperModuleConf} $out/modules/piper-generic.conf
  '';
in
{
  environment.etc."speech-dispatcher".source = speechdConfDir;
  finit.services.speech-dispatcher = {
    description = "speech-dispatcher TTS daemon";
    conditions = "service/dbus/ready";
    command = "${pkgs.speechd}/bin/speech-dispatcher --no-fork --config-dir /etc/speech-dispatcher";
    log = true;
    nohup = true;
  };
}
