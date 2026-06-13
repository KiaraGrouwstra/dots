# nixos config - finix port (`finix-port` branch)

This branch ports the `/etc/nixos` config to run on
[Finix](https://github.com/finix-community/finix) (finit as PID 1, not systemd),
targeting daily-driver parity. The `main` branch keeps the NixOS version of the
same tree, so the per-file diff against `main` is the NixOS -> finix delta.

Finix evaluates its own module tree via `lib.evalModules { class = "nixos"; }`
(it does not call `nixpkgs/nixos`), so this is a rewrite of the system layer,
not a drop-in. The desktop core maps onto Finix's `laptop` profile (the
`standard` stack: udev + elogind + NetworkManager).

Services use finit directly (`finit.services.<name>` / `finit.tasks.<name>`),
matching every upstream Finix service. The portable `system.services.<name>`
abstraction (PR #15) was merged into finix then extracted to a standalone repo,
`finix-community/modular-services` (`nixosModules.default`). It bridges nixpkgs
modular services (`process.argv`) onto `finit.services`. We don't pin it: the
two bespoke daemons here (wireguard task, speech-dispatcher) are simpler as
direct finit units. It pays off only for reusing nixpkgs portable-service defs.

## Layout

- `system.nix` - entry point. Calls `finix.lib.finixSystem { modules = [ ./system ]; }`.
- `system-finix-vm.nix` - VM variant for the boot gate (kernel-direct boot, host
  `/nix/store` over 9p, tmpfs root - does NOT exercise limine/LUKS).
- `finix-rebuild` - rebuild driver (`nixos-rebuild --file system.nix`).
- `finix-vm-run` - launches the VM (`--nographic` for a serial smoke test).
- `system/default.nix` - core wiring: laptop profile, `nixpkgs.pkgs`, identity,
  module imports, home-manager + soteria community modules, and the home bridge
  (imports `../home` as a function, injecting `sources`/`user`/`sysConfig`).
- `system/hardware.nix` - hand-written (nixos-facter won't import): kernel
  modules, zen kernel, graphics, firmware.
- `system/disks.nix` - the existing on-disk layout as plain finix `fileSystems`
  (disko's NixOS module is `modulesPath`-coupled and unused). LUKS unlock is
  finix's `fsType = "luks"` -> `cryptsetup open` (passphrase).
- `system/user.nix` - the user, groups, shell, and package set (incl. the
  `x-terminal-emulator`/`x-www-browser`/`xterm-256color` command wrappers,
  inlined as `writeShellScriptBin` since finix has no `nixpkgs.overlays`).
- `system/vars.nix` - vars on-machine backend + generic generators.
- `system/nix.nix` - `services.nix-daemon.settings` (finix's nix.conf namespace),
  plus the github-pat access-token injected at runtime via vars (placeholder in
  the rendered nix.conf, substituted into the live `/etc/nix/nix.conf` by the
  `templates` generator - same pattern as the wireguard task).
- `system/wireguard.nix` - 3 VPNs as NetworkManager keyfiles assembled at boot by
  a finit task from the `vars` secrets (no `ensureProfiles` in finix; secrets
  read at runtime so the build needs no root and the closure carries none).
- `system/firewall.nix` - nftables ruleset (overrides the profile's): ssh,
  wireguard, incus, kdeconnect ports.
- `system/services.nix` - doas (passwordless wheel), incus, kdeconnect package.
- `system/tts.nix` - speech-dispatcher as a finit service.
- `system/niri/` - niri session, xwayland-satellite, soteria, steam, fonts, and
  the session env (`DISPLAY`/`NIXOS_OZONE_WL`/`EDITOR` via `security.pam.environment`,
  since finix has no `environment.variables`).

The bootloader (limine) and greeter (greetd/regreet) come from the laptop
profile, so there are no local `secure-boot.nix`/`greetd.nix` modules. Custom DNS
(dns.sb) is a NetworkManager `conf.d` drop-in in `system/default.nix` (finix has
no `networking.nameservers`). Nitrokey udev rules are dropped for v1.

## Status

- Eval gate: PASS - `nix build -f system.nix config.system.build.toplevel`
  builds clean as a regular user.
- VM boot gate (automated): PASS - `./finix-vm-run --nographic` boots finit to
  the graphical runlevel; filesystems mount, network comes up, and the ported
  services start OK (NetworkManager, regreet, soteria, speech-dispatcher, rtkit,
  fcron, accounts-daemon, home-manager activation). The headless greeter restart
  loop is a missing-display artifact, not a config bug.

## Remaining manual gates (do not automate)

1. Interactive VM check: run `./finix-vm-run` (graphical, virtio-gpu) and confirm
   regreet login -> niri session -> pipewire audio -> NetworkManager wifi +
   noctalia network/VPN panels -> incus up.
2. Bare-metal switch (only after the VM passes), keeping the NixOS generation to
   roll back to: `doas ./finix-rebuild boot`, reboot, confirm limine boot + LUKS
   passphrase prompt, then `doas ./finix-rebuild switch`.

## Dropped for v1 (revisit later)

lorri (socket-activated; direnv still works), userborn (finix `users`), geoclue2,
zramSwap (no finix module), FIDO2 LUKS unlock (no finit support), lanzaboote
(replaced by limine secureBoot investigation - see `system/secure-boot.nix`),
distributed builds / nix.gc timers / nix-build-cgroup-reaper (systemd-coupled).
