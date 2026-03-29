{ pkgs, ... }:
let
  amyOnnx = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx";
    sha256 = "063c43bbs0nb09f86l4avnf9mxah38b1h9ffl3kgpixqaxxy99mk";
  };
  amyJson = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
    sha256 = "0xvxjxk59byydx9gj6rdvvydp5zm8mzsrf9vyy6x6299sjs3x8lm";
  };
  amyVoice = pkgs.runCommand "piper-voice-en_US-amy-medium" { } ''
    mkdir -p $out
    cp ${amyOnnx} $out/en_US-amy-medium.onnx
    cp ${amyJson} $out/en_US-amy-medium.onnx.json
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
