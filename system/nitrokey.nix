{ pkgs, user, ... }:
{
  # udev rules for Nitrokey FIDO2 + creates nitrokey group
  hardware.nitrokey.enable = true;
  users.users.${user}.extraGroups = [ "nitrokey" ];

  # LUKS unlock at boot by tapping the key.
  # Note: boot.initrd.luks.fido2Support is incompatible with systemd initrd;
  # use crypttabExtraOpts + systemd-cryptenroll instead.
  #
  # Enroll each device (one at a time, while plugged in):
  #   doas systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
  # List enrolled tokens:
  #   doas systemd-cryptenroll /dev/nvme0n1p2
  # Remove all FIDO2 slots (passphrase slot is preserved):
  #   doas systemd-cryptenroll --wipe-slot=fido2 /dev/nvme0n1p2
  boot.initrd.luks.devices."crypted".crypttabExtraOpts = [ "fido2-device=auto" ];

  # PAM U2F: tap key to authenticate; falls back to password when key is absent.
  # control defaults to "sufficient", so this is purely additive — no lockout risk.
  #
  # Register each device once (one at a time, while plugged in):
  #   mkdir -p ~/.config/Yubico
  #   pamu2fcfg > ~/.config/Yubico/u2f_keys          # device 1 — creates file
  #   truncate -s -1 ~/.config/Yubico/u2f_keys       # strip trailing newline
  #   pamu2fcfg -n >> ~/.config/Yubico/u2f_keys      # device 2 — appends on same line
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true; # shows "Please touch your security key" prompt
      timeout = 15; # fall through to password after 15s if key not tapped
    };
  };

  environment.systemPackages = [
    pkgs.libfido2 # fido2-token CLI for device inspection / troubleshooting
  ];
}
