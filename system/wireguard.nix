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
    procolix-vpn4 = {
      endpoint = "vpn4.procolix.net:51820";
      publicKey = "NuLFSBNR9/ut+p/WwEijfYK+Rx7G68oHUMu1jQ22eG8=";
    };
    vpn-fediversity = {
      endpoint = "vpn.fediversity.eu:51820";
      publicKey = "TKTBW6RUjsMc9I9bH31vBUMZZByZVhL7rDENHjEcgyw=";
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
