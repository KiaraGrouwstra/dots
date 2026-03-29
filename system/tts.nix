{ pkgs, sources, ... }:
let
  amyVoice = pkgs.runCommand "piper-voice-en_US-amy-medium" { } ''
    mkdir -p $out
    cp ${sources."piper-amy-onnx"} $out/en_US-amy-medium.onnx
    cp ${sources."piper-amy-json"} $out/en_US-amy-medium.onnx.json
  '';
in
{
  services.speechd = {
    enable = true;
    config = ''
      LogLevel  3
      LogDir  "default"
      DefaultVolume 100
      SymbolsPreproc "char"
      SymbolsPreprocFile "gender-neutral.dic"
      SymbolsPreprocFile "font-variants.dic"
      SymbolsPreprocFile "symbols.dic"
      SymbolsPreprocFile "emojis.dic"
      SymbolsPreprocFile "orca.dic"
      SymbolsPreprocFile "orca-chars.dic"
      Include "clients/*.conf"
      AddModule "piper-generic" "sd_generic" "piper-generic.conf"
      DefaultModule piper-generic
    '';
    modules.piper-generic = ''
      GenericExecuteSynth \
      "printf %s \'$DATA\' | ${pkgs.piper-tts}/bin/piper --model ${amyVoice}/en_US-amy-medium.onnx --output-raw | ${pkgs.alsa-utils}/bin/aplay -r 22050 -f S16_LE -c 1 -t raw - 2>/dev/null"

      GenericCmdDependency "${pkgs.piper-tts}/bin/piper"
      GenericSoundIconFolder "/usr/share/sounds/sound-icons/"

      GenericPunctNone ""
      GenericPunctSome ""
      GenericPunctMost ""
      GenericPunctAll ""

      AddVoice "en" "FEMALE1" "en_US-amy-medium"
      DefaultVoice "en_US-amy-medium"
    '';
  };
}
