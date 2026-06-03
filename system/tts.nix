{ pkgs, sources, ... }:
let
  voicesDir = pkgs.runCommand "piper-voices" { } ''
    mkdir -p $out
    cp ${sources."piper-amy-onnx"} $out/en_US-amy-medium.onnx
    cp ${sources."piper-amy-json"} $out/en_US-amy-medium.onnx.json
    cp ${sources."piper-pim-onnx"} $out/nl_NL-pim-medium.onnx
    cp ${sources."piper-pim-json"} $out/nl_NL-pim-medium.onnx.json
  '';
in
{
  services.speechd = {
    enable = true;
    config = ''
      LogLevel  3
      LogDir  "default"
      DefaultVolume 30
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
      "printf %s \'$DATA\' | ${pkgs.piper-tts}/bin/piper --model ${voicesDir}/$VOICE.onnx --output-raw | ${pkgs.sox}/bin/sox -t raw -r 22050 -e signed -b 16 -c 1 - -t raw -r 22050 -e signed -b 16 -c 1 - tempo 2.0 | ${pkgs.pipewire}/bin/pw-play --raw --volume 0.3 --rate 22050 --format s16 --channels 1 -"

      GenericCmdDependency "${pkgs.piper-tts}/bin/piper"
      GenericCmdDependency "${pkgs.sox}/bin/sox"
      GenericCmdDependency "${pkgs.pipewire}/bin/pw-play"
      GenericSoundIconFolder "/usr/share/sounds/sound-icons/"

      GenericPunctNone ""
      GenericPunctSome ""
      GenericPunctMost ""
      GenericPunctAll ""

      AddVoice "en" "FEMALE1" "en_US-amy-medium"
      AddVoice "nl" "MALE1" "nl_NL-pim-medium"
      DefaultVoice "en_US-amy-medium"
    '';
  };
}
