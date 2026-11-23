#!/usr/bin/env bash
# Firewall for a Dokploy host: SSH, ICMP and replies open; 80/443 only from
# Cloudflare; everything else on the public interface dropped, including the
# panel (:3000) and Swarm (2377, 7946, 4789).
#
# Two paths need filtering, and missing either leaves :3000 open:
#   INPUT        host processes: sshd, dockerd (Swarm) and docker-proxy, which
#                listens on [::] and so carries IPv6 traffic to published ports.
#   DOCKER-USER  published container ports. Docker DNATs them in PREROUTING, so
#                they skip INPUT (and ufw). The match uses --ctorigdstport, the
#                port the client asked for, because after DNAT the destination
#                port is the container's.
#
# Usage: dokploy-firewall.sh install|apply|flush|status
#   install  copy this script to /usr/local/sbin and write the systemd units
#            (does not enable them, so a lockout cannot survive a reboot)
#   apply    fetch Cloudflare ranges and (re)build the rules, IPv4 and IPv6
#   flush    remove every rule this script added (the auto-revert target)
#   status   print the rules
#
# Environment overrides:
#   PUBLIC_IF   public interface (default: the interface of the default route)
#   SSH_PORTS   space-separated SSH ports (default: from `sshd -T`, else 22)
#   EXTRA_TCP   space-separated TCP ports to open to everyone, e.g. "8443"
set -euo pipefail

STATE_DIR=/var/lib/dokploy-firewall
INSTALL_PATH=/usr/local/sbin/dokploy-firewall.sh
CF_URL=https://www.cloudflare.com
IN_CHAIN=DOKPLOY-IN
FWD_CHAIN=DOKPLOY-FWD

die() { echo "dokploy-firewall: $*" >&2; exit 1; }

public_if() {
  if [ -n "${PUBLIC_IF:-}" ]; then echo "$PUBLIC_IF"; return; fi
  ip -o route get 1.1.1.1 | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}'
}

ssh_ports() {
  if [ -n "${SSH_PORTS:-}" ]; then echo "$SSH_PORTS"; return; fi
  local ports
  ports=$(sshd -T 2>/dev/null | awk '$1 == "port" { print $2 }' | tr '\n' ' ')
  echo "${ports:-22}"
}

# Prints the Cloudflare ranges for one family (v4|v6). Writes a fresh download
# to the cache, falls back to the last good cache when the download fails (a
# boot without network must still close :3000), and fails when neither has a
# single valid range, so an empty list never replaces working rules.
cf_ranges() {
  local family=$1 cache="$STATE_DIR/cloudflare-ips-$1" pattern fresh
  if [ "$family" = v4 ]; then
    pattern='^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$'
  else
    pattern='^[0-9a-fA-F:]+:[0-9a-fA-F:]*/[0-9]{1,3}$'
  fi
  mkdir -p "$STATE_DIR"
  fresh=$(curl -fsS --max-time 20 "$CF_URL/ips-$family" 2>/dev/null | tr -d '\r' | grep -E "$pattern" || true)
  if [ -n "$fresh" ]; then
    printf '%s\n' "$fresh" > "$cache.tmp" && mv "$cache.tmp" "$cache"
    printf '%s\n' "$fresh"
  elif [ -s "$cache" ]; then
    echo "dokploy-firewall: Cloudflare $family download failed, using cached list" >&2
    cat "$cache"
  else
    die "no Cloudflare $family ranges (download failed, no cache); rules left unchanged"
  fi
}

# Prints an iptables-restore payload for one family. With --noflush, declaring
# a user chain flushes it, so each apply replaces the two chains in a single
# atomic commit and never leaves a window with the chains empty.
ruleset() {
  local family=$1 ranges=$2 icmp port cidr
  if [ "$family" = v4 ]; then icmp=icmp; else icmp=ipv6-icmp; fi
  echo "*filter"
  echo ":$IN_CHAIN - [0:0]"
  echo ":$FWD_CHAIN - [0:0]"

  echo "-A $IN_CHAIN -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
  # ICMPv6 carries neighbour discovery; dropping it breaks IPv6 entirely.
  echo "-A $IN_CHAIN -p $icmp -j ACCEPT"
  if [ "$family" = v4 ]; then
    echo "-A $IN_CHAIN -p udp --sport 67 --dport 68 -j ACCEPT"
  else
    echo "-A $IN_CHAIN -p udp --dport 546 -j ACCEPT"
  fi
  for port in $(ssh_ports) ${EXTRA_TCP:-}; do
    echo "-A $IN_CHAIN -p tcp --dport $port -j ACCEPT"
  done
  for cidr in $ranges; do
    echo "-A $IN_CHAIN -s $cidr -p tcp -m multiport --dports 80,443 -j ACCEPT"
    echo "-A $IN_CHAIN -s $cidr -p udp --dport 443 -j ACCEPT"
  done
  echo "-A $IN_CHAIN -j DROP"

  # RETURN, not ACCEPT, hands allowed traffic back to Docker's own rules.
  echo "-A $FWD_CHAIN -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN"
  for port in ${EXTRA_TCP:-}; do
    echo "-A $FWD_CHAIN -p tcp -m conntrack --ctorigdstport $port -j RETURN"
  done
  for cidr in $ranges; do
    echo "-A $FWD_CHAIN -s $cidr -p tcp -m conntrack --ctorigdstport 80 -j RETURN"
    echo "-A $FWD_CHAIN -s $cidr -p tcp -m conntrack --ctorigdstport 443 -j RETURN"
    echo "-A $FWD_CHAIN -s $cidr -p udp -m conntrack --ctorigdstport 443 -j RETURN"
  done
  echo "-A $FWD_CHAIN -j DROP"
  echo "COMMIT"
}

ensure_jump() {
  local cmd=$1 chain=$2 iface=$3 target=$4
  "$cmd" -w -C "$chain" -i "$iface" -j "$target" 2>/dev/null ||
    "$cmd" -w -I "$chain" 1 -i "$iface" -j "$target"
}

apply_family() {
  local family=$1 iface=$2 ranges=$3 cmd restore
  if [ "$family" = v4 ]; then cmd=iptables; restore=iptables-restore; else cmd=ip6tables; restore=ip6tables-restore; fi
  ruleset "$family" "$ranges" | "$restore" -w --noflush
  # Docker reuses an existing DOCKER-USER chain and adds the FORWARD jump to it
  # when it starts, so creating it here works before Docker is installed.
  "$cmd" -w -N DOCKER-USER 2>/dev/null || true
  ensure_jump "$cmd" INPUT "$iface" "$IN_CHAIN"
  ensure_jump "$cmd" DOCKER-USER "$iface" "$FWD_CHAIN"
}

cmd_apply() {
  local iface v4 v6
  iface=$(public_if)
  [ -n "$iface" ] || die "cannot detect the public interface; set PUBLIC_IF"
  # Resolve both lists before touching any rule, so a failure changes nothing.
  v4=$(cf_ranges v4)
  v6=$(cf_ranges v6)
  apply_family v4 "$iface" "$v4"
  apply_family v6 "$iface" "$v6"
  echo "dokploy-firewall: applied on $iface (ssh: $(ssh_ports); cloudflare: $(echo "$v4" | wc -l) v4, $(echo "$v6" | wc -l) v6)"
}

cmd_flush() {
  local cmd chain parent
  for cmd in iptables ip6tables; do
    for parent in INPUT:$IN_CHAIN DOCKER-USER:$FWD_CHAIN; do
      chain=${parent%%:*}
      # A jump's interface may differ from today's PUBLIC_IF, so find the rules by target.
      "$cmd" -w -S "$chain" 2>/dev/null | grep -E -- "-j ${parent#*:}\$" | sed 's/^-A /-D /' |
        while read -r rule; do eval "$cmd -w $rule"; done
    done
    for chain in $IN_CHAIN $FWD_CHAIN; do
      "$cmd" -w -F "$chain" 2>/dev/null || true
      "$cmd" -w -X "$chain" 2>/dev/null || true
    done
  done
  echo "dokploy-firewall: flushed"
}

cmd_status() {
  local cmd
  for cmd in iptables ip6tables; do
    echo "== $cmd"
    "$cmd" -w -S INPUT | grep -- "-j $IN_CHAIN" || echo "(no INPUT jump)"
    "$cmd" -w -S DOCKER-USER 2>/dev/null | grep -- "-j $FWD_CHAIN" || echo "(no DOCKER-USER jump)"
    "$cmd" -w -S "$IN_CHAIN" 2>/dev/null || echo "(no $IN_CHAIN chain)"
    "$cmd" -w -S "$FWD_CHAIN" 2>/dev/null || echo "(no $FWD_CHAIN chain)"
  done
}

cmd_install() {
  install -m 0755 "$0" "$INSTALL_PATH"
  # PartOf re-applies after a Docker restart; After without Requires keeps the
  # unit usable before Docker is installed.
  cat > /etc/systemd/system/dokploy-firewall.service <<EOF
[Unit]
Description=Dokploy host firewall
Wants=network-online.target
After=network-online.target docker.service
PartOf=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$INSTALL_PATH apply

[Install]
WantedBy=multi-user.target docker.service
EOF
  cat > /etc/systemd/system/dokploy-firewall-refresh.service <<EOF
[Unit]
Description=Refresh Cloudflare ranges in the Dokploy host firewall
After=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=$INSTALL_PATH apply
EOF
  cat > /etc/systemd/system/dokploy-firewall-refresh.timer <<EOF
[Unit]
Description=Weekly Cloudflare range refresh for the Dokploy host firewall

[Timer]
OnCalendar=weekly
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  echo "dokploy-firewall: installed $INSTALL_PATH and units (not enabled yet)"
}

[ "$(id -u)" -eq 0 ] || die "run as root"
case "${1:-}" in
  install) cmd_install ;;
  apply) cmd_apply ;;
  flush) cmd_flush ;;
  status) cmd_status ;;
  *) die "usage: $0 install|apply|flush|status" ;;
esac
