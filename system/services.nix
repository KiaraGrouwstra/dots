# System services + systemd-coupled daemons ported to finix.
{
  lib,
  pkgs,
  ...
}:
{
  # --- privileges: doas, passwordless for wheel ---
  programs.doas.enable = true;
  programs.sudo.enable = lib.mkForce false;
  environment.etc."doas.conf".text = lib.mkAfter ''
    permit nopass keepenv :wheel
  '';

  programs.shadow.enable = true;

  services.autologin = {
    enable = true;
    user = "kiara";
    command = "dbus-run-session -- niri-session"; # not `niri --session`?
  };

  # --- incus (container/VM hypervisor) ---
  # services.incus.enable = true;

  # --- kdeconnect: just the package; firewall ports live in ./firewall.nix ---
  environment.systemPackages = [
    pkgs.kdePackages.kdeconnect-kde
    pkgs.speechd
  ];
}
