import type { Plugin } from "@opencode-ai/plugin";
import { execSync } from "node:child_process";

const speak = (text: string) => {
  const escaped = text.replace(/'/g, "'\\''");
  try {
    execSync(`/run/current-system/sw/bin/spd-say -w '${escaped}'`, { stdio: "ignore" });
  } catch (e) {
    console.error("[tts] error:", e);
  }
};

const plugin: Plugin = async () => ({
  "experimental.text.complete": async (input, output) => {
    const text = output.text?.trim();
    if (text && text.length > 0 && text.length < 1000) {
      speak(text);
    }
  },
});

export default plugin;
