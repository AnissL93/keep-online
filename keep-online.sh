#!/usr/bin/env bash
# keep-online: ping Tailscale peers; escalate nic restart -> tailscaled restart -> reboot.
set -u

: "${PEERS:?PEERS is required (space-separated Tailscale IPs)}"
INTERVAL=${INTERVAL:-60}
NIC_AFTER=${NIC_AFTER:-3}
TS_AFTER=${TS_AFTER:-5}
REBOOT_AFTER=${REBOOT_AFTER:-15}
REBOOT_MIN_UPTIME=${REBOOT_MIN_UPTIME:-3600}

fail=0

log() { echo "$(date -Is) $*"; }

# 0 if any peer answers one ping within 3s.
probe() {
  local p
  for p in $PEERS; do
    ping -c1 -W3 "$p" >/dev/null 2>&1 && return 0
  done
  return 1
}

uptime_s() { cut -d. -f1 /proc/uptime; }
restart_nic() { nmcli networking off; sleep 3; nmcli networking on; }
restart_tailscaled() { systemctl restart tailscaled; }
reboot_box() { systemctl reboot; }

tick() {
  if probe; then
    (( fail > 0 )) && log "recovered after $fail failures"
    fail=0
    return
  fi
  fail=$((fail + 1))
  log "probe failed ($fail)"
  if (( fail == NIC_AFTER )); then
    log "restarting networking"; restart_nic
  elif (( fail == TS_AFTER )); then
    log "restarting tailscaled"; restart_tailscaled
  elif (( fail >= REBOOT_AFTER )); then
    if (( $(uptime_s) > REBOOT_MIN_UPTIME )); then
      log "rebooting"; reboot_box
    else
      log "reboot suppressed: uptime $(uptime_s)s <= ${REBOOT_MIN_UPTIME}s"
    fi
  fi
}

main() {
  log "started: peers=[$PEERS] interval=${INTERVAL}s nic=$NIC_AFTER ts=$TS_AFTER reboot=$REBOOT_AFTER"
  while true; do
    tick
    sleep "$INTERVAL"
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
