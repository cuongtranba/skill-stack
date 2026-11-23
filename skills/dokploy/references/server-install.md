# Server Install & Hardening

Commands for the **Install Flow** in `SKILL.md`. Run them from the user's machine. The examples use `ADMIN@SERVER` for an SSH login with key auth and passwordless `sudo` (on Debian cloud images, the `debian` user), and these placeholders:

| Placeholder | Meaning |
|-------------|---------|
| `SERVER` | Server hostname or IP used for SSH |
| `PUBLIC_IP` / `PUBLIC_IP6` | Server's public IPv4 / IPv6 (the IPv6 one only if the server has one) |
| `PANEL_HOST` | Panel hostname, e.g. `dokploy.example.com`, in a Cloudflare zone the user controls |
| `ADMIN_EMAIL` | Email the user will register as the Dokploy owner |

The Dokploy installer publishes the panel on `:3000` with open first-user registration: whoever registers first becomes the owner, and the owner gets root on the server. Bots find fresh installs within minutes. Each step below keeps `:3000` unreachable from the internet, so the order matters.

## Step 0: Preflight

```bash
ssh ADMIN@SERVER 'sudo -n true && sudo touch /root/dokploy-install.stamp && (sudo ss -ltnp | grep -E ":(80|443|3000) " || echo "no web ports listening")'
```

- `sudo -n true` must succeed. The flow later disables root and password logins, so a working key login plus `sudo` is the way back in.
- The stamp file marks the install start for the Step 7 audit.
- If something already listens on 80, 443, or 3000, Dokploy may already be installed. If `:3000` has been reachable from the internet, run the Step 7 audit before anything else.

## Step 1: Firewall, before Docker or Dokploy exists

[`dokploy-firewall.sh`](dokploy-firewall.sh) allows SSH, ICMP, DHCP, and established traffic on the public interface; allows 80/443 (TCP, plus UDP 443) only from [Cloudflare's ranges](https://www.cloudflare.com/ips/); and drops everything else, including `:3000` and Swarm's 2377, 7946, and 4789. It covers IPv4 and IPv6, and both paths traffic can take:

- **`INPUT`**: host processes, such as `sshd`, Swarm, and `docker-proxy`. Docker's userland proxy listens on `[::]`, so IPv6 connections to a published port arrive here.
- **`DOCKER-USER`**: published container ports. Docker rewrites the destination in `PREROUTING`, so this traffic never reaches `INPUT`, and `ufw` does not see it either. The rules match `--ctorigdstport`, the port the client connected to, because after the rewrite the destination port is the container's.

It refuses to apply with an empty Cloudflare list. When a download fails, it falls back to the last list it saved (`/var/lib/dokploy-firewall/`), so a reboot without network still blocks `:3000`. Override detection with `PUBLIC_IF=eth0` and `SSH_PORTS="22 2222"`; open an extra public TCP port with `EXTRA_TCP="8443"`.

Copy the script from this skill's `references/` directory and install it. `install` writes the systemd units but does not enable them yet:

```bash
scp references/dokploy-firewall.sh ADMIN@SERVER:/tmp/dokploy-firewall.sh
```

```bash
ssh ADMIN@SERVER 'sudo apt-get update -qq && sudo apt-get install -y -qq iptables curl && sudo bash /tmp/dokploy-firewall.sh install'
```

Arm an auto-revert, then apply. If the rules cut SSH off, the timer flushes them after 3 minutes:

```bash
ssh ADMIN@SERVER 'sudo systemd-run --unit=dokploy-firewall-revert --on-active=180 /usr/local/sbin/dokploy-firewall.sh flush && sudo /usr/local/sbin/dokploy-firewall.sh apply'
```

Open a **new** SSH connection. When it works, cancel the revert and enable the units: `dokploy-firewall.service` re-applies the rules at boot and after every Docker start, and the timer refreshes the Cloudflare ranges weekly:

```bash
ssh -o ConnectTimeout=10 ADMIN@SERVER 'sudo systemctl stop dokploy-firewall-revert.timer && sudo systemctl enable --now dokploy-firewall.service dokploy-firewall-refresh.timer'
```

If the new connection fails, wait for the revert, then check `sudo sshd -T | grep ^port` and re-apply with `SSH_PORTS` set.

The rules use the `iptables` command, which on current Debian and Ubuntu drives nftables, the same backend Docker uses. Docker's opt-in native nftables firewall backend has no `DOCKER-USER` chain. If `dockerd` runs with `"firewall-backend": "nftables"`, this script does not filter published ports, so keep the default backend.

## Step 2: Install Dokploy

```bash
ssh ADMIN@SERVER 'curl -sSL https://dokploy.com/install.sh | sudo ADVERTISE_ADDR=PUBLIC_IP sh'
```

Then confirm the firewall survived Docker's startup. Both `iptables` and `ip6tables` need the `INPUT` and `DOCKER-USER` jumps:

```bash
ssh ADMIN@SERVER 'sudo /usr/local/sbin/dokploy-firewall.sh status | grep -- "-j DOKPLOY"'
```

Probe from the user's machine, which is outside the server. Every line must print `000` (no response):

```bash
curl -s -m 5 -o /dev/null -w "3000 %{http_code}\n" "http://PUBLIC_IP:3000/"; curl -s -m 5 -o /dev/null -w "80 %{http_code}\n" "http://PUBLIC_IP/"; curl -sk -m 5 -o /dev/null -w "443 %{http_code}\n" "https://PUBLIC_IP/"
```

When the server has IPv6 and the user's machine can reach IPv6, also probe it: `curl -6 -s -m 5 -o /dev/null -w "%{http_code}\n" "http://[PUBLIC_IP6]:3000/"`. Any HTTP status means a port is open: stop and fix the firewall before Step 3.

## Step 3: Register the owner over an SSH tunnel

```bash
ssh -fN -o ExitOnForwardFailure=yes -L 3000:localhost:3000 ADMIN@SERVER
```

Ask the user to open `http://localhost:3000` and register with `ADMIN_EMAIL`. The user types the password; the agent never handles it. Then check that exactly one account exists and that it is the user's:

```bash
ssh ADMIN@SERVER 'sudo docker exec $(sudo docker ps -qf name=dokploy-postgres) psql -U dokploy -d dokploy -c "select u.email, m.role, u.created_at from \"user\" u left join member m on m.user_id = u.id order by u.created_at;"'
```

Expect one row: `ADMIN_EMAIL`, role `owner`. Any other row means someone else registered, and that account can reach root: treat the server as compromised (see **Compromise indicators** in `SKILL.md`). If a column is missing on another Dokploy version, list the columns with `\d "user"` and `\d member` and adapt the query.

Next, have the user create an API key in the dashboard, still at `http://localhost:3000`, and run the **Setup Flow** with `api_endpoint` set to `https://PANEL_HOST/api` and `request_profile` set to `origin-tunnel` (`ssh_target` `ADMIN@SERVER`, `local_port` `3000`), so API calls use the tunnel until the panel domain works.

## Step 4: Panel domain

In Cloudflare (the user does this, or the agent with a Cloudflare API token the user provides):

1. Add a **proxied** (orange-cloud) `A` record `PANEL_HOST` → `PUBLIC_IP`, and `AAAA` → `PUBLIC_IP6` if the server has IPv6.
2. Set the zone's SSL/TLS mode to **Full (strict)**. Cloudflare then requires a valid certificate on the server. Flexible would send panel logins over plain HTTP between Cloudflare and the server.

Assign the domain through the API, over the tunnel:

```bash
curl -s -X POST "http://localhost:3000/api/settings.assignDomainServer" -H "Content-Type: application/json" -H "x-api-key: API_KEY" -d '{"host":"PANEL_HOST","certificateType":"letsencrypt","letsEncryptEmail":"ADMIN_EMAIL","https":true}'
```

Dokploy writes a Traefik router on the `websecure` entrypoint with `certResolver: letsencrypt`. Let's Encrypt's HTTP-01 challenge works through the Cloudflare proxy: Cloudflare passes `/.well-known/acme-challenge/` to the server even with *Always Use HTTPS* on, and a certificate usually arrives within seconds. Until then the panel answers 526. Confirm:

```bash
ssh ADMIN@SERVER 'sudo grep -E "websecure|certResolver" /etc/dokploy/traefik/dynamic/dokploy.yml; echo | openssl s_client -connect 127.0.0.1:443 -servername PANEL_HOST 2>/dev/null | openssl x509 -noout -issuer -enddate'
```

```bash
curl -s -o /dev/null -w "%{http_code}\n" "https://PANEL_HOST/"
```

The issuer must be Let's Encrypt and the status 200. Once both hold, set `request_profile` back to `null` in `.dokploy.json` and close the tunnel (`pkill -f "3000:localhost:3000"`).

Newer Dokploy versions have `settings.togglePanelPort`, which stops publishing `:3000` altogether. Dokploy only accepts the call through `PANEL_HOST`, and afterwards the `origin-tunnel` profile no longer works. Keep the firewall either way.

## Step 5: App domains

Every app domain needs `"https": true` and `"certificateType": "letsencrypt"` (Deploy Flow Step 8). Under Full (strict), Cloudflare rejects an origin without a valid certificate, so an HTTP-only domain answers 526 or 404.

## Step 6: SSH hardening

Arm a revert first, then switch to key-only logins without root:

```bash
ssh ADMIN@SERVER 'sudo systemd-run --unit=dokploy-ssh-revert --on-active=180 sh -c "rm -f /etc/ssh/sshd_config.d/10-dokploy-hardening.conf && systemctl reload ssh" && printf "PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin no\n" | sudo tee /etc/ssh/sshd_config.d/10-dokploy-hardening.conf && sudo sshd -t && sudo systemctl reload ssh'
```

`sshd` keeps the first value it reads, and the `10-` prefix sorts before cloud-init's `50-cloud-init.conf`, which often sets `PasswordAuthentication yes`. Use `PermitRootLogin prohibit-password` instead if something needs root key logins. Then, from a **new** connection, confirm and cancel the revert:

```bash
ssh -o ConnectTimeout=10 ADMIN@SERVER 'sudo sshd -T | grep -E "^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin) " && sudo systemctl stop dokploy-ssh-revert.timer'
```

## Step 7: Post-install audit

```bash
ssh ADMIN@SERVER 'sudo docker exec $(sudo docker ps -qf name=dokploy-postgres) psql -U dokploy -d dokploy -c "select u.email, m.role, u.created_at from \"user\" u left join member m on m.user_id = u.id;" -c "select s.ip_address, s.created_at, u.email from session s join \"user\" u on u.id = s.user_id order by s.created_at;"'
```

```bash
ssh ADMIN@SERVER 'for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do echo "== $f"; sudo cat "$f" 2>/dev/null; done'
```

```bash
ssh ADMIN@SERVER 'sudo find /etc/systemd/system /usr/lib/systemd/system /etc/cron.d /var/spool/cron -newer /root/dokploy-install.stamp -type f 2>/dev/null; ps -eo pid,user,pcpu,etime,args --sort=-pcpu | head -12'
```

Expect: one user, sessions only from the user's IPs, only SSH keys the user recognises, and new units limited to Docker, containerd, and `dokploy-firewall*`. The top CPU processes should be Docker, Dokploy, Postgres, Redis, and Traefik, mostly idle. Anything else: see **Compromise indicators** in `SKILL.md`.

## Verification checklist

Report each line as pass or fail:

- [ ] `http://PUBLIC_IP:3000`, `http://PUBLIC_IP`, `https://PUBLIC_IP` from outside: no response (`000`); same for `PUBLIC_IP6` when present
- [ ] `https://PANEL_HOST` through Cloudflare: 200
- [ ] Origin certificate for `PANEL_HOST` issued by Let's Encrypt and unexpired (Full (strict) accepts it)
- [ ] Exactly one Dokploy user, `ADMIN_EMAIL`, role `owner`
- [ ] No SSH key the user does not recognise in any `authorized_keys`
- [ ] `dokploy-firewall.service` and `dokploy-firewall-refresh.timer` enabled; revert timers gone
- [ ] `sshd -T`: `passwordauthentication no`, `permitrootlogin no` (or `prohibit-password`)
