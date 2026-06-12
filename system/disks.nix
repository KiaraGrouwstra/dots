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
{ ... }:
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
  boot.initrd.supportedFilesystems.luks.enable = true;
  boot.initrd.supportedFilesystems.btrfs.enable = true;
  boot.supportedFilesystems.btrfs.enable = true;

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
