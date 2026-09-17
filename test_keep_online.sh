#!/usr/bin/env bash
# Self-check for keep-online.sh escalation order. Run: bash test_keep_online.sh
set -eu
cd "$(dirname "$0")"

PEERS="100.64.0.1"
source ./keep-online.sh

# Stubs: probe always fails, actions record their names, nothing sleeps or logs.
probe() { return 1; }
restart_nic() { calls+=(restart_nic); }
restart_tailscaled() { calls+=(restart_tailscaled); }
reboot_box() { calls+=(reboot_box); }
log() { :; }

run_ticks() { local i; for ((i = 0; i < $1; i++)); do tick; done; }

# 1. uptime high: full escalation, reboot fires once because only REBOOT_AFTER ticks are run.
calls=(); fail=0
uptime_s() { echo 99999; }
run_ticks 15
[[ "${calls[*]}" == "restart_nic restart_tailscaled reboot_box" ]] || { echo "FAIL 1: ${calls[*]}"; exit 1; }

# 2. uptime low: reboot suppressed even well past REBOOT_AFTER.
calls=(); fail=0
uptime_s() { echo 10; }
run_ticks 20
[[ "${calls[*]}" == "restart_nic restart_tailscaled" ]] || { echo "FAIL 2: ${calls[*]}"; exit 1; }

# 3. a successful probe resets the counter and triggers nothing.
calls=(); fail=0
uptime_s() { echo 99999; }
run_ticks 2
probe() { return 0; }
tick
[[ $fail == 0 && ${#calls[@]} == 0 ]] || { echo "FAIL 3: fail=$fail calls=${calls[*]}"; exit 1; }

# 4. reboot suppressed by low uptime, then re-armed once uptime is high.
calls=(); fail=0
probe() { return 1; }
uptime_s() { echo 10; }
run_ticks 16
uptime_s() { echo 99999; }
tick
[[ "${calls[*]}" == "restart_nic restart_tailscaled reboot_box" ]] || { echo "FAIL 4: ${calls[*]}"; exit 1; }

echo "OK"
