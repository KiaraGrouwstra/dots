{
  # pkgs,
  pins,
  # user,
  ...
}:
{
  imports = with pins; [
    # <disko/module.nix>
    nixos-facter-modules.modules.nixos.facter
    vars.options
    vars.backends.on-machine
    # ./disks.nix
    # ./user.nix
    # ./vars.nix
  ];
}
