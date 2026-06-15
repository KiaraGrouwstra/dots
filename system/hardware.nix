# Hand-written hardware config (nixos-facter won't import under finix).
# Machine: Lenovo laptop, AMD Ryzen 5 7530U (Radeon iGPU), single NVMe.
# Seeded from the running system's loaded modules + block layout.
{ pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [
    "kvm-amd"
    "amdgpu"
    "mt7921e"
    "snd_hda_intel"
    "btusb"
    "uvcvideo"
    "snd_usb_audio"
    "ccp"
    "k10temp"
    "i2c_piix4"
    "piix4_smbus"
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # AMD microcode + GPU firmware (linux-firmware comes from the laptop profile).
  hardware.firmware = [ pkgs.linux-firmware ];

  # `/boot` ESP and the decrypted btrfs root are declared in ./disks.nix.
}
