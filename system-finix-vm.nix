# Finix VM variant - for the Phase 6 VM gate.
#
# Finix's qemu module boots the kernel directly (bootMode = "kernel") with the
# host /nix/store mounted over 9p, so the VM does NOT exercise limine or the
# LUKS passphrase unlock (those are bare-metal only with this layout) - it
# overrides ./disks.nix's root with a tmpfs/host-store boot. The VM verifies the
# rest: finit boot, niri/regreet session, pipewire, NetworkManager, incus, home
# activation.
#
# Build the qemu command, then run it:
#   nix build -f system-finix-vm.nix config.virtualisation.qemu.argv ...
# (see ./finix-vm-run for a launcher)
let
  sources = import ./npins;
  finix = import "${sources.finix}";
in
finix.lib.finixSystem {
  lib = (import "${sources.nixpkgs}" { }).lib;
  modules = [
    ./system
    # Register `virtiofs` as a known filesystem so the initrd module's
    # auto-derivation (it maps every neededForBoot fsType to
    # `supportedFilesystems.<fsType>.enable`) accepts the store mount below.
    # Finix ships such a module for 9p (modules/filesystems/9p.nix) but not
    # virtiofs; this mirrors it and pulls the `virtiofs` kernel module into the
    # initrd when enabled.
    (
      { config, lib, ... }:
      {
        options.boot.initrd.supportedFilesystems.virtiofs.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        options.boot.supportedFilesystems.virtiofs.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        config = {
          boot.kernelModules = lib.mkIf config.boot.supportedFilesystems.virtiofs.enable [ "virtiofs" ];
          boot.initrd.kernelModules = lib.mkIf config.boot.initrd.supportedFilesystems.virtiofs.enable [
            "virtiofs"
          ];
        };
      }
    )
    (
      { lib, ... }:
      {
        imports = [ "${sources.finix}/modules/virtualisation/qemu.nix" ];

        # VM boots kernel-direct off the host store; the real LUKS/btrfs
        # fileSystems from ./disks.nix don't apply in the VM. Provide a tmpfs
        # root and drop the luks container entry.
        virtualisation.qemu.mountHostNixStore = true;
        virtualisation.memorySize = 4096;
        virtualisation.cores = 4;

        # Share the host /nix/store over virtiofs, not 9p. QEMU's in-process 9p
        # `local` server is single-threaded and collapses under the parallel
        # store reads of a graphical session (niri/regreet/pipewire), dropping
        # the transport - the guest then sees "Transport endpoint is not
        # connected" (errno 107). virtiofsd is a multi-threaded host daemon over
        # vhost-user, which holds up under that load. The finix qemu module
        # hardcodes the 9p mount + `-virtfs` arg, so override both: force the
        # store mount to virtiofs here and have ./finix-vm-run launch virtiofsd
        # and pass the vhost-user device instead of `-virtfs`.
        fileSystems."/nix/.ro-store" = lib.mkForce {
          device = "nix-store";
          fsType = "virtiofs";
          neededForBoot = true;
        };

        # Serial console so `finix-vm-run --nographic` shows kernel + finit logs.
        boot.kernelParams = [ "console=ttyS0" ];

        # Replace the bare-metal LUKS/btrfs layout from ./disks.nix with a
        # tmpfs root. The qemu module's own `/nix/store` 9p bind is left intact
        # (mkForce per-entry, not on the whole attrset, so it still merges).
        fileSystems = {
          "/" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
            options = [ "mode=0755" ];
          };
          # Drop the encrypted bare-metal entries (point them at the tmpfs root
          # so they are harmless no-ops the initrd can satisfy).
          "crypted" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
          };
          "/persist" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
            neededForBoot = true;
          };
          "/var/log" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
            neededForBoot = true;
          };
          "/nix" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
          };
          "/boot" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
          };
        };
        swapDevices = lib.mkForce [ ];
        boot.initrd.supportedFilesystems.luks.enable = lib.mkForce false;
      }
    )
  ];
}
