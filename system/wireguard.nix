# Wireguard VPNs as NetworkManager keyfile connection profiles.
#
# noctalia's VPNService.qml only sees NM-managed wireguard (`nmcli ... type
# wireguard`), so we model the VPNs as NM keyfiles rather than the nixpkgs
# `networking.wireguard` module (which finix lacks and which would be
# networkd-managed). Finix's NetworkManager module has no `ensureProfiles`, so
# we drop keyfiles into /etc/NetworkManager/system-connections/ directly.
#
# Secrets (privateKey, presharedKey, ips, allowedIPs) come from the same
# `vars.generators` as the NixOS config. ALL of them are read at *runtime* by a
# finit task (not at build time), so the build never needs root access to
# /etc/vars/secret and the closure carries no secret material. ips/allowedIPs
# are nix-expression list files (e.g. `[ "10.0.0.2/32" ]`); the task converts
# them to NM's `;`-separated form with a small `nix-instantiate` eval.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = ks: {
    # TODO: use clan.core.vars' `prompts.<name>.persist`
    script = ''cp -R "$prompts"/. "$out/"'';
    prompts = lib.genAttrs ks (_: { });
    files = lib.genAttrs ks (_: { secret = true; });
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

  # Keyfile template with @PLACEHOLDER@s for every secret; the finit task
  # substitutes them at boot from the runtime vars paths.
  mkKeyfile = name: peer: ''
    [connection]
    id=${name}
    type=wireguard
    interface-name=${name}
    autoconnect=false

    [wireguard]
    private-key=@PRIVATE_KEY@

    [wireguard-peer.${peer.publicKey}]
    endpoint=${peer.endpoint}
    allowed-ips=@ALLOWED_IPS@
    persistent-keepalive=25
    ${lib.optionalString (peer.presharedKey or false) "preshared-key=@PRESHARED_KEY@"}

    [ipv4]
    method=manual
    address1=@ADDRESS@

    [ipv6]
    method=ignore
  '';

  # Read a vars file that contains a nix list of strings and emit them
  # `;`-separated (NM keyfile list syntax).
  nixListToSemicolons = path: ''
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E \
      'builtins.concatStringsSep ";" (import ${path})' | sed 's/^"//; s/"$//'
  '';
in
{
  vars.generators = lib.mapAttrs (_: peer: secrets (fileNamesFor peer)) vpns;

  # Assemble NM keyfiles at boot from the templates + runtime secrets, then
  # reload NetworkManager so the profiles appear to nmcli / noctalia.
  finit.tasks.wireguard-nm-profiles = {
    description = "assemble NetworkManager wireguard keyfiles from secrets";
    conditions = "service/network-manager/ready";
    user = "root";
    path = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.nix
      config.services.networkmanager.package
    ];
    command = pkgs.writeShellScript "wireguard-nm-profiles" (
      ''
        set -eu
        dir=/etc/NetworkManager/system-connections
        mkdir -p "$dir"
      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: peer:
          let
            template = pkgs.writeText "${name}.nmconnection.tmpl" (mkKeyfile name peer);
            f = config.vars.generators.${name}.files;
          in
          ''
            out="$dir/${name}.nmconnection"
            cp ${template} "$out"
            address=$(${nixListToSemicolons f.ips.path})
            allowed=$(${nixListToSemicolons f.allowedIPs.path})
            sed -i "s|@PRIVATE_KEY@|$(cat ${f.privateKey.path})|" "$out"
            sed -i "s|@ADDRESS@|$address|" "$out"
            sed -i "s|@ALLOWED_IPS@|$allowed|" "$out"
            ${lib.optionalString (peer.presharedKey or false)
              ''sed -i "s|@PRESHARED_KEY@|$(cat ${f.presharedKey.path})|" "$out"''}
            chmod 600 "$out"
          ''
        ) vpns
      )
      + ''
        nmcli connection reload || true
      ''
    );
    log = true;
  };
}
