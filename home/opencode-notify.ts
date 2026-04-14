import type { Plugin } from "@opencode-ai/plugin";
import { execSync } from "node:child_process";

const bell = () => process.stderr.write("\x07");

const notify = (summary: string, body?: string) => {
  const args = body ? `${quote(summary)} ${quote(body)}` : quote(summary);
  try {
    execSync(`notify-send ${args}`, { stdio: "ignore" });
  } catch {}
};

const quote = (s: string) => `'${s.replace(/'/g, "'\\''")}'`;

const plugin: Plugin = async () => ({
  event: async ({ event }) => {
    switch (event.type) {
      case "permission.asked":
        bell();
        notify("OpenCode", "Permission requested");
        break;
      case "session.idle":
        bell();
        notify("OpenCode", "Done");
        break;
      case "session.error":
        bell();
        notify("OpenCode", "Error");
        break;
    }
  },
});

export default plugin;
