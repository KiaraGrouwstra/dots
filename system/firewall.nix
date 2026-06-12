# nftables firewall.
#
# Finix's laptop profile ships a raw nftables `configFile` (no
# `networking.firewall` abstraction), so we override it wholesale and fold in
# the extra open ports this machine needs:
#   - sshd 22                 (kept from the profile base)
#   - wireguard 51820 tcp+udp (VPNs)
#   - incus 8443 tcp          (remote API)
#   - kdeconnect 1714-1764 tcp+udp
{ pkgs, lib, ... }:
{
  services.nftables.configFile = lib.mkForce (pkgs.writeText "nftables.conf" ''
    flush ruleset

    table inet firewall {
      chain incoming {
        type filter hook input priority 0; policy drop;

        # established/related connections
        ct state established,related accept

        # invalid connections
        ct state invalid drop

        # loopback interface
        iifname lo accept

        # icmp
        icmp type echo-request accept
        icmpv6 type { echo-request, nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept

        # open tcp ports: sshd (22), incus (8443), wireguard (51820),
        # kdeconnect (1714-1764)
        tcp dport { 22, 8443, 51820, 1714-1764 } accept

        # open udp ports: wireguard (51820), kdeconnect (1714-1764)
        udp dport { 51820, 1714-1764 } accept
      }
    }
  '');
}
