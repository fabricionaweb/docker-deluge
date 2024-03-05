Just another Deluge image. But compiled from the source.

---

**Environments**

- `USE_VPN` set it to require VPN

**Needed docker arguments**

- `--cap-add=NET_ADMIN`
- `--sysctl="net.ipv4.conf.all.src_valid_mark=1"`
- `--sysctl="net.ipv6.conf.all.disable_ipv6=1"`

**Suggested setup using PostUp/PreDown hooks**

1. Set your `LAN_CIDR` with docker environments eg: `10.0.0.0/24` or `192.168.0.0/24`
1. `BR_GATEWAY`, `BR_DEV`, `BR_CIDR` are exported from [.profile](./rootfs/root/.profile) and should be available on interative shell, otherwise needs to load `source /root/.profile`
1. Add or replace **PostUp** and **PreDown** on your `/config/wg0.conf`

   ```
   # LAN_CIDR comes from docker env
   PostUp  = ip route add $LAN_CIDR via $BR_GATEWAY dev $BR_DEV
   PostUp  = iptables -I OUTPUT ! -d $LAN_CIDR ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
   PostUp  = iptables -I OUTPUT -s $BR_CIDR -d $BR_CIDR -j ACCEPT
   PreDown = ip route del $LAN_CIDR
   PreDown = iptables -F OUTPUT
   ```
