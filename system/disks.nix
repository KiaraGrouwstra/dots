# Disk layout for finix.
#
# The partitioning was done once by disko under NixOS (GPT: ESP + LUKS, with a
# btrfs filesystem and subvolumes inside the crypt). Finix does not run disko's
# NixOS module (it is `modulesPath`-coupled and assumes a systemd initrd), and
# its initrd unlocks LUKS by running a plain `cryptsetup open` for every
# `fileSystems` entry whose `fsType = "luks"`. So we describe the *existing*
# on-disk layout declaratively rather than re-deriving it from disko.
#
# btrfs subvolumes root/persist/log/nix/swap, zstd-compressed, noatime;
# passphrase-unlocked LUKS (FIDO2 unlock dropped - no finit equivalent).
{ lib, pkgs, ... }:
let
  espPart = "/dev/disk/by-partlabel/disk-main-ESP";
  luksPart = "/dev/disk/by-partlabel/disk-main-luks";
  cryptDev = "/dev/mapper/crypted";

  btrfsOpts = subvol: [
    "subvol=${subvol}"
    "compress=zstd"
    "noatime"
  ];
in
{
  # cryptsetup's passphrase prompt runs as finit's `task tty:@console`, which
  # resolves via /sys/class/tty/console/active. With no `console=` on the cmdline
  # that is tty0 (/dev/console), not a readable input VT, so cryptsetup reads EOF
  # -> "No key available with this passphrase" in a retry loop. Pin the console to
  # tty1 (a real VT) so the prompt takes keyboard input. Drop the laptop profile's
  # `splash` (plymouth service is off) and raise loglevel so the prompt is visible.
  #
  # ./disks.nix is shared with the VM entry point (system-finix-vm.nix imports
  # ./system too), which needs `console=ttyS0` instead. mkForce here is priority
  # 50; the VM overrides at mkOverride 49 (higher priority) so its serial console
  # wins without a same-priority conflict.
  programs.plymouth.enable = lib.mkForce false;
  boot.kernelParams = lib.mkForce [
    "console=tty1"
    "loglevel=4"
  ];

  # --- boot isolation: keep limine off the EFI fallback slot ---
  # With `canTouchEfiVariables` unset, limine's installer sets
  # `efiInstallAsRemovable=true` and writes the firmware fallback app
  # `EFI/BOOT/BOOTX64.EFI` - the same slot systemd-boot (NixOS) uses, so the two
  # bootloaders fight over it. Enabling EFI var writes makes limine install to
  # `EFI/limine/BOOTX64.EFI` and register its own "Limine" efibootmgr entry,
  # leaving the fallback slot + `EFI/systemd/` to NixOS's systemd-boot. The
  # firmware BootOrder then cleanly selects between finix (Limine) and NixOS.
  # Safe: the machine boots UEFI and systemd-boot already writes EFI vars.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # libseat's seatd backend needs a running seatd daemon. Finix uses elogind +
  # seatd for seat management (the systemd logind backend is dropped via overlay
  # in ./default.nix because its RPATH points at a split-output systemd that
  # lacks libsystemd.so.0, breaking cage). Enabling this also wires the `greeter`
  # user into the seatd group (the finix regreet module gates that on
  # `services.seatd.enable`).
  # services.seatd.enable = lib.mkForce true;
  services.elogind.enable = lib.mkForce true;

  # `@console` resolves to tty0 (the foreground-VT proxy), not tty1, so finit
  # binds tty0 as the fs-import task's controlling terminal and cryptsetup's
  # getpass() reads /dev/tty == tty0 while the kernel echoes keystrokes on the
  # real VT (tty1) -> the typed passphrase never reaches cryptsetup. Bind the
  # task's controlling terminal directly to tty1.
  boot.initrd.consoleDevice = lib.mkForce "/dev/tty1";

  # --- diagnostic (revert after; unauthenticated initrd root shell) ---
  # On switch-root failure this drops to a rescue shell on @console instead of
  # `reboot -f` after 10s, letting us confirm whether /sysroot mounted (rules
  # hypothesis A in or out). Only triggers if switch-root FAILS; if stage 2 is
  # reached (hypothesis B) the system proceeds past it.
  boot.initrd.emergencyAccess = true;

  # --- hypothesis-B fix: deterministic stage-2 VT ownership ---
  # At runlevel 3 getty owns tty1 (inherits the generic `runlevels = "234"`) while
  # greetd's `terminal.vt = "next"` opens regreet on a different, invisible VT -
  # the kernel console (console=tty1) keeps the getty login in front -> apparent
  # hang. Pin greetd to vt 1 (the console the kernel shows) and vacate tty1 from
  # getty so the two don't contend. Keep tty2-6 as fallback console logins.
  # services.greetd.settings.terminal.vt = lib.mkForce "1";

  # --- capture greeter output (the missing diagnostic trail) ---
  # The generated greetd finit stanza has no `log` keyword, so cage/regreet
  # stdout+stderr are discarded - the reason the greeter failure left no trace.
  # Redirect them to a persisted file under /var/log (the `log` btrfs subvol,
  # neededForBoot) so the next boot's failure is readable from tty1-6 or the
  # rollback generation. `finit.services.greetd.log` -> finit's `logit` wrapper
  # (<finix>/modules/finit/default.nix:272).
  # finit.services.greetd.log = "/var/log/greetd.log";

  # Also surface what regreet/cage themselves think went wrong.
  programs.regreet.debug = true;
  programs.regreet.compositor.environment = {
    WLR_BACKENDS = "drm,libinput";
  };
  # disable the competing greeter (it's pulled in by the laptop profile / regreet)
  services.greetd.enable = lib.mkForce true;
  programs.regreet.enable = lib.mkForce true;
  # services.greetd.enable = lib.mkForce false;
  # programs.regreet.enable = lib.mkForce false;

  # --- restore a usable tty1 instead of a blank echoing console ---
  # With the greeter failing, tty1 is a bare kernel console. Put a getty back on
  # tty1 so the "hang" becomes a login prompt we can use on the machine to run
  # `initctl status greetd`, `cat /var/log/greetd.log`, `chvt`, `dmesg`. greetd
  # still owns vt1 when it runs; on greeter exit the getty is the fallback.
  services.getty.ttys = lib.mkForce [ "tty1" "tty2" "tty3" "tty4" "tty5" "tty6" ];

  # --- ungated debug shell (revert after diagnosis) ---
  # Every getty/greetd is gated on <service/elogind/ready> (elogind injects that
  # condition onto every finit.ttys entry, <finix>/modules/services/elogind/default.nix:30).
  # If any link in udevd->syslogd->dbus->elogind never readies, all of them stay
  # blocked and nothing logs - which is what we see. This tty bypasses the gate:
  # `conditions = lib.mkForce []` defeats the elogind injection (verified: the tty
  # render only emits a <...> clause when conditions != [], <finix>/modules/finit/default.nix:675),
  # `nologin` gives an immediate root shell, and runlevels include S so the prompt
  # appears even if finit never advances past runlevel S.
  finit.ttys.debug = {
    device = "/dev/tty12";       # static kernel VT, exists without udev; off the console=tty1 path
    conditions = lib.mkForce [ ];
    nologin = true;
    nowait = true;
    runlevels = "S12345";
  };

  # --- permanent dm-node fix (keep after diagnostics are reverted) ---
  # cryptsetup here is built `with UDEV`, so `cryptsetup open` hands /dev/mapper node
  # creation to udev rather than mknod-ing it. The finix initrd ships no device-mapper
  # udev rules and no dmsetup, so the node never appears and every /dev/mapper/crypted
  # mount fails -> /sysroot empty -> switch-root aborts. Add lvm2 (provides dmsetup) to
  # the initrd so the fallback below can create the node without udev.
  boot.initrd.supportedFilesystems.luks.packages = lib.mkForce [ pkgs.cryptsetup pkgs.lvm2.bin ];

  # The node /dev/mapper/crypted is normally created by lvm2's 10-dm.rules
  # (SYMLINK+="mapper/$env{DM_NAME}"), which the finix initrd does not ship. We cannot
  # add it user-side: the udev module owns /etc/udev/rules.d as a single directory
  # symlink built from a hardcoded allowlist (<finix>/modules/services/udev/default.nix:121-135,
  # 307-312) that excludes dm and ignores services.udev.packages in the initrd, and a
  # per-file boot.initrd.contents entry collides with that directory symlink in
  # makeInitrdNG. So we rely entirely on the udev-independent dmsetup fallback below.
  # (Upstream fix: extend finix's initrdUdevRules to ship the dm rules.)

  # udev does not create /dev/mapper/crypted in the initrd (no dm rules shipped, plus a
  # halted stage-1 udevd). dmsetup mknodes creates the node directly from the live kernel
  # dm mapping, with no udev dependency - the same trick finix's LVM path uses
  # (<finix>/modules/filesystems/lvm.nix:58). Idempotent; harmless if udev already made it.
  boot.initrd.fileSystemImportCommands = lib.mkMerge [
    # Order 400 < luks.nix's `mkOrder 500` (the `cryptsetup open`), so this runs
    # BEFORE the unlock. `mkBefore` is also order 500 and ties with luks - the tie
    # breaks in luks's favour (module load order), so it would run after. Use an
    # explicit lower order to win.
    (lib.mkOrder 400 ''
      # cryptsetup here is built `with UDEV`, so `cryptsetup open` issues the dm-create
      # ioctl then calls dm_udev_wait(), blocking on a udev cookie until udevd processes
      # the uevent. The finix stage-1 udevd is halted / ships no dm rules, so the cookie
      # is never dropped and `cryptsetup open` hangs until finit's 120s bootstrap timeout
      # SIGTERMs fs-import -> switch-root on an empty /sysroot. DM_DISABLE_UDEV=1 makes
      # libdevmapper fall back to creating /dev/mapper/crypted directly (mknod) and skip
      # the udev cookie wait entirely (introduced in libdevmapper 1.02.78; this build is
      # 2.03.39). Exported here so the `cryptsetup open` child (luks.nix, mkOrder 500)
      # inherits it. Keep `dmsetup mknodes` below as a harmless redundant fallback.
      export DM_DISABLE_UDEV=1

      # Pre-unlock tty diagnostic (revert with the other debug bits). Persisted to
      # the unencrypted ESP so it survives the reboot into NixOS. All `|| true`-
      # guarded so it never changes the script's exit status.
      ( mkdir -p /tmp/esp 2>/dev/null || true
        if mount -t vfat /dev/disk/by-partlabel/disk-main-ESP /tmp/esp 2>/dev/null; then
          {
            echo "=== FINIX PRE-UNLOCK TTY DIAG $(cat /proc/uptime 2>/dev/null) ==="
            echo "-- /proc/cmdline --";                cat /proc/cmdline 2>&1 || true
            echo "-- /sys/class/tty/console/active --"; cat /sys/class/tty/console/active 2>&1 || true
            echo "-- fs-import ctty (fd 0/1/2) --";     ls -l /proc/self/fd/0 /proc/self/fd/1 /proc/self/fd/2 2>&1 || true
            echo "-- tty --";                           tty 2>&1 || true
            echo "-- registered consoles --";           dmesg 2>/dev/null | grep -i "console \[" || true
          } >> /tmp/esp/finix-tty-diag.txt 2>&1 || true
          umount /tmp/esp 2>/dev/null || true
        fi
      ) || true
    '')
    (lib.mkAfter ''
      dmsetup mknodes || true

      # --- diagnostics (revert with the other debug bits once boot succeeds) ---
      # fs-import runs as `task tty:@console`, so this dump is visible on screen, and we
      # also persist it to the unencrypted ESP so it survives the reboot into NixOS for
      # offline reading. Everything is `|| true`-guarded: this block must never change the
      # script's exit status (which drives <task/fs-import/{success,failure}>).
      {
        echo "=== FINIX FS-IMPORT DIAG $(cat /proc/uptime 2>/dev/null) ==="
        echo "-- ls -l /dev/mapper --";       ls -l /dev/mapper 2>&1 || true
        echo "-- dmsetup ls --";              dmsetup ls 2>&1 || true
        echo "-- dmsetup info crypted --";    dmsetup info crypted 2>&1 || true
        echo "-- cryptsetup status crypted --"; cryptsetup status crypted 2>&1 || true
        echo "-- ls -l /dev/disk/by-partlabel --"; ls -l /dev/disk/by-partlabel 2>&1 || true
      } > /dev/console 2>&1 || true

      # persist the same snapshot to the ESP (unencrypted; readable from NixOS afterwards)
      ( mkdir -p /tmp/esp 2>/dev/null || true
        if mount -t vfat /dev/disk/by-partlabel/disk-main-ESP /tmp/esp 2>/dev/null; then
          {
            echo "=== FINIX FS-IMPORT DIAG $(cat /proc/uptime 2>/dev/null) ==="
            ls -l /dev/mapper 2>&1 || true
            dmsetup ls 2>&1 || true
            dmsetup info crypted 2>&1 || true
            cryptsetup status crypted 2>&1 || true
            dmesg 2>/dev/null | tail -50 || true
          } >> /tmp/esp/finix-diag.txt 2>&1 || true
          umount /tmp/esp 2>/dev/null || true
        fi
      ) || true
    '')
  ];

  boot.initrd.supportedFilesystems.luks.enable = true;
  boot.initrd.supportedFilesystems.btrfs.enable = true;
  boot.supportedFilesystems.btrfs.enable = true;

  # --- diagnostic: make the unencrypted ESP mountable in stage 1 ---
  # The diagnostic dump below persists to the ESP (vfat) so it survives the reboot
  # into NixOS for offline reading. vfat is not otherwise in the initrd; this wires
  # the vfat kmod + nls_cp437 + nls_iso8859-1 (<finix>/modules/filesystems/vfat.nix).
  # Harmless to keep; can be dropped with the diagnostics.
  boot.supportedFilesystems.vfat.enable = true;
  boot.initrd.supportedFilesystems.vfat.enable = true;

  fileSystems = {
    # LUKS container. fsType = "luks" makes the initrd run
    #   cryptsetup open <options> <device> crypted
    # before mounting the real filesystems below. `options` are passed verbatim
    # to cryptsetup (matching disko's allowDiscards + bypassWorkqueues).
    "crypted" = {
      device = luksPart;
      fsType = "luks";
      options = [
        "--allow-discards"
        "--perf-no_read_workqueue"
        "--perf-no_write_workqueue"
      ];
    };

    "/" = {
      device = cryptDev;
      fsType = "btrfs";
      options = btrfsOpts "root";
    };

    "/persist" = {
      device = cryptDev;
      fsType = "btrfs";
      options = btrfsOpts "persist";
      neededForBoot = true;
    };

    "/var/log" = {
      device = cryptDev;
      fsType = "btrfs";
      options = btrfsOpts "log";
      neededForBoot = true;
    };

    "/nix" = {
      device = cryptDev;
      fsType = "btrfs";
      options = btrfsOpts "nix";
    };

    "/boot" = {
      device = espPart;
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  swapDevices = [
    { device = "/.swapvol/swapfile"; }
  ];
}
