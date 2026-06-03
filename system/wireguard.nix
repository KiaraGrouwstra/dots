{
  config,
  lib,
  ...
}:
let
  secrets = ks: {
    # TODO: use clan.core.vars' `prompts.<name>.persist`
    script = ''cp -R "$prompts"/. "$out/"'';
    prompts = lib.genAttrs ks (_: { });
    files = lib.genAttrs ks (_: {
      secret = true;
    });
  };
  baseFileNames = [
    "privateKey"
    "ips"
    "allowedIPs"
  ];
  vpns = {
    procolix-vpn = {
      endpoint = "vpn.procolix.eu:51820";
      publicKey = "YHHnx/LcB1meyQj4nrhtzvEiQLJ8HloHj+e94U8EhEM=";
    };
    vpn-fediversity = {
      endpoint = "vpn.fediversity.eu:51820";
      publicKey = "HWSb8vjhJ6VOL9NWqtV6LYxDQMY5CDKu8RtJuyepvyk=";
      # Portal-issued config requires a preshared key.
      presharedKey = true;
    };
    vpn-office = {
      endpoint = "kantoorvpn.procolix.eu:51820";
      publicKey = "9j0IR8ZVMnmI9MOeqbFBqSmZXrjnPhG9t/xO+p1kiR0=";
    };
  };
  # Per-VPN secret file names: add `presharedKey` when the peer needs one.
  fileNamesFor = peer: baseFileNames ++ lib.optional (peer.presharedKey or false) "presharedKey";
in
{
  vars.generators = lib.mapAttrs (_: peer: secrets (fileNamesFor peer)) vpns;
  networking.wireguard = {
    enable = true;
    useNetworkd = true;
    interfaces = lib.mapAttrs (k: peer: {
      ips = import config.vars.generators.${k}.files.ips.path;
      privateKeyFile = config.vars.generators.${k}.files.privateKey.path;
      peers = [
        (lib.mkMerge [
          (removeAttrs peer [ "presharedKey" ])
          {
            persistentKeepalive = 25;
            allowedIPs = import config.vars.generators.${k}.files.allowedIPs.path;
          }
          (lib.mkIf (peer.presharedKey or false) {
            presharedKeyFile = config.vars.generators.${k}.files.presharedKey.path;
          })
        ])
      ];
    }) vpns;
  };
  networking.firewall.allowedTCPPorts = [
    51820
  ];
  networking.firewall.allowedUDPPorts = [
    51820
  ];
}
