#!/usr/bin/env bash
# Flight readiness poll.
#
# Work you have not started is reported as "not started" and does NOT fail.
# Only something you have actually begun can hold the launch, so it is safe to
# start anywhere and work at your own pace.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

G="\033[32m"; R="\033[31m"; Y="\033[33m"; D="\033[2m"; B="\033[1m"; N="\033[0m"
FAIL=0; STARTED=""; DONE_LIST=""

section() { printf "\n${B}%s${N}\n" "$1"; }
go()    { printf "  ${G}GO   ${N} %s\n" "$1"; }
nogo()  { printf "  ${R}NO-GO${N} %s\n     ${D}↳ %s${N}\n" "$1" "$2"; FAIL=1; MFAIL=1; }
idle()  { printf "  ${D}·     %s${N}\n" "$1"; }
note()  { printf "  ${Y}·     %s${N}\n" "$1"; }

# has this mission been started at all?
has_work() { [ -d "src/sol$1" ] && [ -n "$(find "src/sol$1" -type f ! -name '.gitkeep' 2>/dev/null | head -1)" ]; }

# ─────────────────────────────── SETUP ──────────────────────────────────
# Not a Sol. Reported so your first push shows something, and it never fails.
section "SETUP"
if [ -f callsign.txt ]; then
  CS=$(tr -d '[:space:]' < callsign.txt)
  if [[ "$CS" =~ ^[A-Z0-9]{3,16}$ ]]; then
    go "callsign = $CS"
  else
    note "callsign.txt should be 3-16 chars, A-Z and 0-9, upper case. Got: '$CS'"
  fi
else
  idle "no callsign yet — echo \"YOURNAME\" > callsign.txt"
fi
[ -f MISSION_LOG.md ] && go "mission log started ($(wc -w < MISSION_LOG.md) words)" \
  || idle "no mission log yet — there's a template in the repo"

# ──────────────────────────────── SOL 1 ────────────────────────────────
section "SOL 001 — BOOT SEQUENCE"
MFAIL=0
if [ ! -f FLAG.txt ] && ! has_work 1; then
  idle "not started"
else
  STARTED="$STARTED 1"
  if [ -f callsign.txt ]; then
    CS=$(tr -d '[:space:]' < callsign.txt)
    [[ "$CS" =~ ^[A-Z0-9]{3,16}$ ]] && go "callsign = $CS" \
      || nogo "callsign.txt malformed" "3-16 chars, A-Z and 0-9, upper case. Got: '$CS'"
  else
    nogo "callsign.txt missing" "Create it at the repo root with your chosen callsign."
  fi

  if [ -f FLAG.txt ]; then
    FL=$(tr -d '[:space:]' < FLAG.txt)
    [[ "$FL" =~ ^[0-9a-f]{16}$ ]] && go "flag submitted (verified at mission control)" \
      || nogo "FLAG.txt malformed" "16 lowercase hex characters. Run: ./tools/vanguard flag"
  else
    nogo "FLAG.txt missing" "Recover the mission directory. Run: ./tools/vanguard flag"
  fi

  PKG=src/sol1/first_light
  { [ -f "$PKG/package.xml" ] && [ -f "$PKG/setup.py" ]; } \
    && go "package present at $PKG" \
    || nogo "no package at $PKG" "See handbook/06-workspace-and-packages.md"
  ls "$PKG"/first_light/*.py >/dev/null 2>&1 \
    && go "node source present" || nogo "no node in $PKG/first_light/" "See handbook/07-first-node.md"

  { [ -f MISSION_LOG.md ] && [ "$(wc -w < MISSION_LOG.md)" -gt 60 ]; } \
    && go "mission log written" \
    || nogo "MISSION_LOG.md missing or too short" "A few honest sentences. Honesty scores points."

  if [ -f "$PKG/package.xml" ] && command -v colcon >/dev/null 2>&1 && [ -d /opt/ros/jazzy ]; then
    set +u; source /opt/ros/jazzy/setup.bash; set -u
    BD=$(mktemp -d); mkdir -p "$BD/src"; cp -r src/sol1/* "$BD/src/" 2>/dev/null || true
    if (cd "$BD" && colcon build --symlink-install >/tmp/colcon.log 2>&1); then
      if grep -q "Failed to parse ROS package manifest" /tmp/colcon.log; then
        BADMAIL=$(grep -o 'Invalid email "[^"]*"' /tmp/colcon.log | head -1)
        nogo "package.xml is invalid — $BADMAIL" \
             "ros2 pkg create copied your git email into package.xml. Fix it there (or run: git config --global user.email 'you@example.com' and recreate the package), then rebuild."
      else
      go "colcon build succeeded"
      set +u; source "$BD/install/setup.bash" 2>/dev/null; set -u
      if timeout 25 bash -c '
          ros2 run first_light circle > /tmp/node.log 2>&1 & NODE=$!
          sleep 6
          timeout 8 ros2 topic echo /turtle1/cmd_vel --once > /tmp/echo.log 2>&1; RC=$?
          kill $NODE 2>/dev/null; exit $RC'; then
        go "node publishes on /turtle1/cmd_vel"
      else
        nogo "nothing on /turtle1/cmd_vel" "Publish geometry_msgs/msg/Twist. Entry point must be named 'circle'."
      fi
      fi
    else
      nogo "colcon build failed" "$(tail -3 /tmp/colcon.log 2>/dev/null | tr '\n' ' ')"
    fi
    rm -rf "$BD"
  fi
  [ "$MFAIL" -eq 0 ] && DONE_LIST="$DONE_LIST 1"
fi

# ──────────────────────────────── SOL 2 ────────────────────────────────
section "SOL 014 — ROLLING CHASSIS"
MFAIL=0
if ! has_work 2; then
  idle "not started"
else
  STARTED="$STARTED 2"
  find src/sol2 \( -name '*.urdf' -o -name '*.xacro' \) 2>/dev/null | grep -q . \
    && go "robot description present" \
    || nogo "no .urdf or .xacro under src/sol2/" "See the Sol 2 sheet."
  grep -rqs 'base_link' src/sol2 && go "base_link frame defined" \
    || nogo "no base_link" "ROS assumes a link called base_link exists."
  W=$(grep -rhos 'wheel' src/sol2 --include='*.urdf' --include='*.xacro' 2>/dev/null | wc -l)
  [ "$W" -ge 4 ] && go "wheels defined ($W references)" \
    || nogo "fewer than 4 wheels found" "This is a four-wheel rover."
  grep -rqs 'tf_topic' src/sol2 && go "DiffDrive publishes odom TF" \
    || note "no <tf_topic> found — without it odom→base_link never appears (handbook/12)"
  grep -rqs 'cmd_vel' src/sol2 && go "publishes to /cmd_vel" \
    || nogo "nothing references cmd_vel" "Your driving node must publish Twist."
  grep -rqs 'odom' src/sol2 && go "uses /odom" \
    || nogo "nothing references odom" "Close the loop on odometry."
  [ "$MFAIL" -eq 0 ] && DONE_LIST="$DONE_LIST 2"
fi

# ──────────────────────────────── SOL 3 ────────────────────────────────
section "SOL 031 — EYES"
MFAIL=0
if ! has_work 3; then
  idle "not started"
else
  STARTED="$STARTED 3"
  find src/sol3 -name '*.py' 2>/dev/null | grep -q . && go "sources present" \
    || nogo "no Python under src/sol3/" "See the Sol 3 sheet."
  grep -rqs 'cv_bridge\|CvBridge' src/sol3 && go "cv_bridge used" \
    || nogo "no cv_bridge usage" "Needed to convert ROS images to OpenCV."
  grep -rqs 'aruco\|Aruco\|ArUco' src/sol3 && go "marker detection present" \
    || nogo "no ArUco usage" "Marker detection is required."
  grep -rqs 'test_images\|expected.json' src/sol3 \
    && go "runs against the provided test images" \
    || nogo "no reference to the test images" "See the Sol 3 sheet."
  grep -rqs 'camera_info\|CameraInfo' src/sol3 && go "camera intrinsics used" \
    || nogo "no camera_info usage" "Pose estimation needs camera intrinsics."
  grep -rqs 'TransformStamped\|sendTransform\|TransformBroadcaster' src/sol3 \
    && go "publishes marker TF" || nogo "no TF broadcast" "Publish the marker as a TF frame."
  [ "$MFAIL" -eq 0 ] && DONE_LIST="$DONE_LIST 3"
fi

# ──────────────────────────────── SOL 4 ────────────────────────────────
section "SOL 067 — TERRA INCOGNITA  (bonus)"
if ! has_work 4; then
  idle "not attempted — this costs you nothing"
else
  STARTED="$STARTED 4"
  grep -rqs 'LaserScan' src/sol4 && go "reads the laser" || note "no LaserScan subscription"
  grep -rqs 'NavigateToPose' src/sol4 && go "commands Nav2" || note "no NavigateToPose action client"
  grep -rqs 'send_goal_async' src/sol4 && go "uses the async action API" \
    || note "no send_goal_async — a blocking client will deadlock"
  grep -rqs 'OccupancyGrid' src/sol4 && go "reads the map" || note "no OccupancyGrid subscription"
  grep -rqs 'TRANSIENT_LOCAL\|transient_local' src/sol4 && go "map QoS set correctly" \
    || note "no transient-local QoS — you will receive no map at all"
  { [ -f src/sol4/NOTES.md ] && [ "$(wc -w < src/sol4/NOTES.md)" -gt 250 ]; } \
    && go "notes written ($(wc -w < src/sol4/NOTES.md) words)" \
    || note "NOTES.md missing or under 250 words"
  find src/sol4 -name '*.rviz' 2>/dev/null | grep -q . && go "RViz config committed" || note "no .rviz config"
  find src/sol4 \( -name '*.yaml' -o -name '*.pgm' \) 2>/dev/null | grep -q . \
    && go "saved map present" || note "no saved map"
  DONE_LIST="$DONE_LIST 4"   # bonus never fails
fi

# ─────────────────────────────── SUMMARY ───────────────────────────────
printf "\n${B}────────────────────────────────────────${N}\n"
if [ -z "$STARTED" ]; then
  printf "${D}Nothing started yet. Your first Sol sheet is in sols/ — good luck.${N}\n\n"
  exit 0
fi
printf "Started:%s   Complete:%s\n" "${STARTED:-  none}" "${DONE_LIST:-  none}"
if [ "$FAIL" -eq 0 ]; then
  printf "${G}${B}ALL STATIONS GO.${N}  ${D}Dare mighty things.${N}\n\n"
else
  printf "${R}${B}HOLD — not finished yet.${N}\n"
  printf "${D}This is a progress report, not an error. A red run just means the Sol you\n"
  printf "have started isn't complete. Nothing you have or haven't pushed counts\n"
  printf "against you, and Sols you haven't begun are ignored entirely.${N}\n\n"
  exit 1
fi
