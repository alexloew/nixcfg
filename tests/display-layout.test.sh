#!/usr/bin/env bash
# Pure fixture tests: no Nix evaluation, compositor IPC or systemd operations.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/home/desktop/display-layout.sh"
layout_jq() { jq "$@"; }

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_equal() { [ "$1" = "$2" ] || fail "$3 (expected $2, got $1)"; }
expect_status() {
  local expected=$1 actual=0
  shift
  "$@" || actual=$?
  assert_equal "$actual" "$expected" "exit status for $*"
}

# Only the fields the layout policy consumes. eDP-1 remains in inventory when
# the lid is closed, but has no logical geometry.
docked='{
  "DP-1":{"make":"Dell Inc.","model":"AW3423DWF","serial":"wide","logical":{"x":0,"y":0,"scale":1}},
  "DP-2":{"make":"Dell Inc.","model":"AW2725DF","serial":"small","logical":{"x":3440,"y":0,"scale":1}},
  "eDP-1":{"make":"Samsung","model":"0x4165","serial":null,"logical":null}
}'
swapped=$(jq '. as $o | .["DP-1"] = $o["DP-2"] | .["DP-2"] = $o["DP-1"]' <<<"$docked")
single=$(jq '.["DP-2"].logical = null' <<<"$docked")
opened=$(jq '.["eDP-1"].logical = {x:6000,y:0,scale:2}' <<<"$docked")
laptop=$(jq '.["DP-1"].logical = null | .["DP-2"].logical = null' <<<"$opened")
no_outputs=$(jq 'map_values(.logical = null)' <<<"$docked")
correct='[{"name":"web","output":"DP-1"},{"name":"terminal","output":"DP-1"},{"name":"chat","output":"DP-2"},{"name":"media","output":"DP-2"}]'
wrong=$(jq 'map(.output = (if .output == "DP-1" then "DP-2" else "DP-1" end))' <<<"$correct")

reset_fixture() {
  test_tick=0 test_limit=12 test_watching=false test_busy_until=0
  test_fail_outputs=false test_fail_workspaces=false
  test_repaired=false test_drift_tick=999 test_swap_on_first=false
  test_apply=true test_apply_request=false test_requests=0 test_arrangements=0
  test_window_tick=999 test_fix_on_request=0 test_service_active=true
  test_windows='[{"id":1,"app_id":"herdr-app"}]'
  test_new_windows='[{"id":1,"app_id":"herdr-app"},{"id":2,"app_id":"slack"}]'
  test_actual=$correct
  test_outputs=( "$docked" )
}
# Simulated time advances only in the parent shell, including between samples.
sleep() {
  test_tick=$((test_tick + 1))
  [ "$test_watching" = false ] || [ "$test_tick" -le "$test_limit" ]
}
niri_json() {
  local index=$test_tick
  case "$1" in
    outputs)
      [ "$test_fail_outputs" = false ] || return 1
      [ "$index" -lt "${#test_outputs[@]}" ] || index=$((${#test_outputs[@]} - 1))
      printf '%s\n' "${test_outputs[$index]}"
      ;;
    workspaces)
      [ "$test_fail_workspaces" = false ] || return 1
      if [ "$test_tick" -ge "$test_drift_tick" ] && [ "$test_repaired" = false ]; then
        printf '%s\n' "$wrong"
      else
        printf '%s\n' "$test_actual"
      fi
      ;;
    windows)
      if [ "$test_tick" -ge "$test_window_tick" ]; then
        printf '%s\n' "$test_new_windows"
      else
        printf '%s\n' "$test_windows"
      fi
      ;;
    *) fail "unexpected IPC request: $*" ;;
  esac
}
layout_flock() {
  if [ "$1" = -n ] && [ "$test_tick" -le "$test_busy_until" ]; then return 1; fi
}
layout_service_is_running() { [ "$test_service_active" = true ]; }
apply_expected_placement() {
  test_actual=$(jq 'to_entries | map({name:.key,output:.value})' <<<"$expected_workspaces")
}
arrange_docked() {
  test_arrangements=$((test_arrangements + 1))
  if [ "$test_apply" = true ]; then apply_expected_placement; fi
  if [ "$test_swap_on_first" = true ] && [ "$test_arrangements" -eq 1 ]; then
    test_outputs=( "$swapped" )
  fi
}
arrange_laptop() { arrange_docked; }
request_layout_reconciliation() {
  test_requests=$((test_requests + 1))
  if [ "$test_apply_request" = true ]; then
    apply_expected_placement
    test_repaired=true
    test_service_active=true
  elif [ "$test_requests" -eq "$test_fix_on_request" ]; then
    apply_expected_placement
  fi
}
run_watcher() { test_watching=true; watch_display_layout; }

reset_fixture
read_layout_outputs
assert_equal "$uw" DP-1 "ultrawide selection"
assert_equal "$aw" DP-2 "27-inch selection"
assert_equal "$edp" '' "closed panel excluded"
workspaces=$correct
layout_workspaces_match || fail "correct placement rejected"
workspaces=$wrong
expect_status 1 layout_workspaces_match
original_signature=$signature
# Connector enumeration order must not change the signature.
test_outputs=( "$(jq 'to_entries | reverse | from_entries' <<<"$docked")" )
read_layout_outputs
assert_equal "$signature" "$original_signature" "stable object ordering"
# Physical identities swapping the same connector keys must change it.
test_outputs=( "$swapped" )
read_layout_outputs
[ "$signature" != "$original_signature" ] || fail "identity swap invisible"
assert_equal "$uw" DP-2 "ultrawide follows identity"
test_outputs=( "$(jq '.["DP-1"].logical.x = 10' <<<"$docked")" )
read_layout_outputs
[ "$signature" != "$original_signature" ] || fail "geometry change invisible"
echo 'PASS: identity-aware signatures and swapped placement detection'

reset_fixture
test_outputs=( "$opened" )
read_layout_outputs
assert_equal "$(jq -r .notes <<<"$expected_workspaces")" eDP-1 "open lid notes target"
apply_expected_placement
workspaces=$test_actual
layout_workspaces_match || fail "open lid placement rejected"
test_outputs=( "$docked" )
read_layout_outputs
expect_status 1 layout_workspaces_match # stale notes must be removed
for fixture in "$single" "$laptop"; do
  test_outputs=( "$fixture" )
  read_layout_outputs
  assert_equal "$(jq 'keys | length' <<<"$expected_workspaces")" 3 "fallback workspace count"
  apply_expected_placement
  workspaces=$test_actual
  layout_workspaces_match || fail "fallback placement rejected"
done
echo 'PASS: lid-open/closed and single-output policy'

reset_fixture
test_outputs=( "$single" "$single" "$docked" )
wait_for_stable_layout_outputs
assert_equal "$test_tick" 5 "wait for final docked topology"
assert_equal "$aw" DP-2 "second monitor detected after reconnect"
reset_fixture
for ((i = 0; i < 20; i++)); do
  if ((i % 2)); then test_outputs[$i]=$single; else test_outputs[$i]=$docked; fi
done
expect_status 1 wait_for_stable_layout_outputs
assert_equal "$test_tick" 12 "bounded settle attempts"
echo 'PASS: staggered reconnect and bounded settling'

reset_fixture
test_actual=$wrong
reconcile_display_layout
assert_equal "$test_arrangements" 1 "swapped placement corrected"
reset_fixture
test_swap_on_first=true
reconcile_display_layout
assert_equal "$test_arrangements" 2 "topology change during moves retries"
assert_equal "$uw" DP-2 "retry refreshes connector mapping"
reset_fixture
test_actual=$wrong test_apply=false
expect_status 75 reconcile_display_layout
assert_equal "$test_arrangements" 3 "bounded correction attempts"
reset_fixture
test_outputs=( "$no_outputs" )
expect_status 2 reconcile_display_layout
assert_equal "$test_arrangements" 0 "no moves with zero outputs"
reset_fixture
test_fail_outputs=true
expect_status 75 reconcile_display_layout
assert_equal "$test_arrangements" 0 "IPC errors never imply usable topology"
echo 'PASS: final placement verification, retries and suspend deferral'

reset_fixture
run_watcher
assert_equal "$test_requests" 0 "correct layout produces no restarts"
reset_fixture
test_drift_tick=5 test_apply_request=true
run_watcher
assert_equal "$test_requests" 1 "workspace drift corrected without connector change"
reset_fixture
test_actual=$wrong
run_watcher
assert_equal "$test_requests" 3 "persistent mismatch has bounded request budget"
reset_fixture
test_actual=$wrong test_busy_until=99
run_watcher
assert_equal "$test_requests" 0 "in-flight layout never interrupted"
reset_fixture
test_window_tick=5
run_watcher
assert_equal "$test_requests" 1 "new managed window reconciled once"
reset_fixture
test_fail_workspaces=true
expect_status 1 run_watcher
assert_equal "$test_requests" 0 "workspace IPC failures do not request layout resets"
reset_fixture
test_fail_outputs=true
expect_status 1 run_watcher
assert_equal "$test_tick" 3 "output IPC failure reconnect is bounded"
assert_equal "$test_requests" 0 "output IPC failures do not request layout resets"
reset_fixture
test_outputs=( "$no_outputs" )
run_watcher
assert_equal "$test_requests" 0 "no requests with zero outputs"
echo 'PASS: self-healing watcher, no-op/busy guards and retry budget'

reset_fixture
test_outputs=( "$docked" "$docked" "$docked" "$docked" "$docked" "$swapped" )
test_apply_request=true
run_watcher
assert_equal "$test_requests" 1 "connector identity swap reconciled once"
assert_equal "$uw" DP-2 "watcher refreshes physical monitor mapping"
reset_fixture
moved=$(jq '.["DP-2"].logical.x = 3500' <<<"$docked")
test_outputs=( "$docked" "$docked" "$docked" "$docked" "$docked" "$moved" )
run_watcher
assert_equal "$test_requests" 1 "geometry change reconciles even when placement matches"
reset_fixture
test_new_windows='[{"id":1,"app_id":"herdr-app"},{"id":2,"app_id":"firefox"}]'
test_window_tick=5
run_watcher
assert_equal "$test_requests" 0 "unmanaged windows do not trigger reflow"
reset_fixture
test_actual=$wrong test_busy_until=5 test_apply_request=true
run_watcher
assert_equal "$test_requests" 1 "drift after a busy pass is not lost"
reset_fixture
test_actual=$wrong test_fix_on_request=3 test_drift_tick=9 test_limit=14
run_watcher
assert_equal "$test_requests" 6 "successful placement re-arms the retry budget"
reset_fixture
test_service_active=false test_apply_request=true
run_watcher
assert_equal "$test_requests" 1 "failed service recovers even when placement already matches"
reset_fixture
test_service_active=false
run_watcher
assert_equal "$test_requests" 3 "service recovery is bounded"
echo 'PASS: settled topology changes, lock recovery and budget/service recovery'

echo 'All display layout regression tests passed.'
