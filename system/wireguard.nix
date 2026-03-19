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
  fileNames = [
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
      publicKey = "TKTBW6RUjsMc9I9bH31vBUMZZByZVhL7rDENHjEcgyw=";
    };
    vpn-office = {
      endpoint = "kantoorvpn.procolix.com:51820";
      publicKey = "gEuso2o73wIK0s8XqXaiZ8CTy+MXKRtS5YHKrFRIphQ=";
    };
  };
in
{
  vars.generators = lib.mapAttrs (_: _: secrets fileNames) vpns;
  networking.wireguard = {
    enable = true;
    useNetworkd = true;
    interfaces = lib.mapAttrs (k: peer: {
      ips = import config.vars.generators.${k}.files.ips.path;
      privateKeyFile = config.vars.generators.${k}.files.privateKey.path;
      peers = [
        (lib.mkMerge [
          peer
          {
            persistentKeepalive = 25;
            allowedIPs = import config.vars.generators.${k}.files.allowedIPs.path;
          }
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
