# keep-online

Keeps a Linux box reachable over Tailscale. Pings a fixed list of peers every
minute; when none answer it escalates:

1. after 3 failures — `nmcli networking off/on`
2. after 5 failures — `systemctl restart tailscaled`
3. after 15 failures — `systemctl reboot` (only if uptime > 1 hour)

Requires NetworkManager, systemd, tailscaled.

## Install

    sudo make install PEERS="100.64.0.1 100.64.0.2"
    journalctl -fu keep-online

## Configure

All knobs are `Environment=` lines in the unit. Change them with
`sudo systemctl edit keep-online`:

| Var | Default | Meaning |
|-----|---------|---------|
| `PEERS` | — | Space-separated Tailscale IPs. Any one answering = online. |
| `INTERVAL` | 60 | Seconds between probes |
| `NIC_AFTER` | 3 | Failures before networking restart |
| `TS_AFTER` | 5 | Failures before tailscaled restart |
| `REBOOT_AFTER` | 15 | Failures before reboot |
| `REBOOT_MIN_UPTIME` | 3600 | No reboot if uptime is below this (seconds) |

## Caveat

"Unreachable" means **every** listed peer is silent. List peers that are
always on. If all of them go away, this box reboots once per
`REBOOT_MIN_UPTIME` until they come back.

## Uninstall / test

    sudo make uninstall
    make test
