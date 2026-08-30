#!/usr/bin/env bash
# Sol 1 flight readiness poll. Runs locally and in CI — same script, same result.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

G="\033[32m"; R="\033[31m"; B="\033[1m"; N="\033[0m"
FAIL=0
station() { printf "\n${B}%s${N}\n" "$1"; }
go()   { printf "  ${G}GO   ${N} %s\n" "$1"; }
nogo() { printf "  ${R}NO-GO${N} %s\n     ↳ %s\n" "$1" "$2"; FAIL=1; }

station "COMMS"
if [ -f callsign.txt ]; then
  CS=$(tr -d '[:space:]' < callsign.txt)
  if [[ "$CS" =~ ^[A-Z0-9]{3,16}$ ]]; then
    go "callsign = $CS"
  else
    nogo "callsign.txt malformed" "3-16 characters, A-Z and 0-9 only, upper case. Got: '$CS'"
  fi
else
  nogo "callsign.txt missing" "Create it at the repo root with your chosen callsign."
fi

station "AUTHENTICATION"
if [ -f FLAG.txt ]; then
  FL=$(tr -d '[:space:]' < FLAG.txt)
  if [[ "$FL" =~ ^[0-9a-f]{16}$ ]]; then
    go "flag submitted (verified at mission control)"
  else
    nogo "FLAG.txt malformed" "Expected 16 lowercase hex characters. Run: ./tools/vanguard flag"
  fi
else
  nogo "FLAG.txt missing" "Complete the .mission/ recovery. Run: ./tools/vanguard flag"
fi

station "PAYLOAD"
PKG=src/sol1/first_light
if [ -f "$PKG/package.xml" ] && [ -f "$PKG/setup.py" ]; then
  go "ROS 2 package present at $PKG"
else
  nogo "package not found at $PKG" "See handbook/06-workspace-and-packages.md"
fi
if ls "$PKG"/first_light/*.py >/dev/null 2>&1; then
  go "node source present"
else
  nogo "no node source in $PKG/first_light/" "See handbook/07-first-node.md"
fi

station "FLIGHT LOG"
if [ -f MISSION_LOG.md ] && [ "$(wc -w < MISSION_LOG.md)" -gt 60 ]; then
  go "mission log written"
else
  nogo "MISSION_LOG.md missing or too short" "At least a few sentences. Honesty scores points."
fi

station "BUILD"
if command -v colcon >/dev/null 2>&1 && [ -d /opt/ros/jazzy ]; then
  set +u; source /opt/ros/jazzy/setup.bash; set -u
  BUILD_DIR=$(mktemp -d)
  mkdir -p "$BUILD_DIR/src"
  cp -r src/sol1/* "$BUILD_DIR/src/" 2>/dev/null || true
  if (cd "$BUILD_DIR" && colcon build --symlink-install >/tmp/colcon.log 2>&1); then
    go "colcon build succeeded"
    set +u; source "$BUILD_DIR/install/setup.bash" 2>/dev/null; set -u
    if timeout 25 bash -c '
        ros2 run first_light circle > /tmp/node.log 2>&1 &
        NODE=$!
        sleep 6
        timeout 8 ros2 topic echo /turtle1/cmd_vel --once > /tmp/echo.log 2>&1
        RC=$?
        kill $NODE 2>/dev/null
        exit $RC'; then
      go "node publishes on /turtle1/cmd_vel"
    else
      nogo "no messages seen on /turtle1/cmd_vel" \
           "Node must publish geometry_msgs/msg/Twist. Entry point must be named 'circle'."
    fi
  else
    nogo "colcon build failed" "Last lines:$(tail -5 /tmp/colcon.log 2>/dev/null | sed 's/^/       /')"
  fi
  rm -rf "$BUILD_DIR"
else
  printf "  ---- ROS 2 not available here; build check skipped (CI will run it)\n"
fi

printf "\n"
if [ "$FAIL" -eq 0 ]; then
  printf "${G}${B}ALL STATIONS GO — Sol 1 complete.${N}\n\n"
else
  printf "${R}${B}HOLD — fix the NO-GO lines above.${N}\n\n"
  exit 1
fi
