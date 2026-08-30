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
has_work() { [ -d "src/task$1" ] && [ -n "$(find "src/task$1" -type f ! -name '.gitkeep' 2>/dev/null | head -1)" ]; }

# ──────────────────────────────── TASK 1 ────────────────────────────────
section "TASK 1 — SETUP"
MFAIL=0
if [ ! -f callsign.txt ] && [ ! -f FLAG.txt ] && ! has_work 1; then
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

  PKG=src/task1/first_light
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
    BD=$(mktemp -d); mkdir -p "$BD/src"; cp -r src/task1/* "$BD/src/" 2>/dev/null || true
    if (cd "$BD" && colcon build --symlink-install >/tmp/colcon.log 2>&1); then
      # colcon only WARNS on a bad package.xml, then builds something that
      # ros2 run can never find. Catch it here or the next line is baffling.
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

# ──────────────────────────────── TASK 2 ────────────────────────────────
section "TASK 2 — ROVER"
MFAIL=0
if ! has_work 2; then
  idle "not started"
else
  STARTED="$STARTED 2"
  find src/task2 \( -name '*.urdf' -o -name '*.xacro' \) 2>/dev/null | grep -q . \
    && go "robot description present" \
    || nogo "no .urdf or .xacro under src/task2/" "See the Task 2 sheet."
  grep -rqs 'base_link' src/task2 && go "base_link frame defined" \
    || nogo "no base_link" "ROS assumes a link called base_link exists."
  W=$(grep -rhos 'wheel' src/task2 --include='*.urdf' --include='*.xacro' 2>/dev/null | wc -l)
  [ "$W" -ge 4 ] && go "wheels defined ($W references)" \
    || nogo "fewer than 4 wheels found" "This is a four-wheel rover."
  grep -rqs 'tf_topic' src/task2 && go "DiffDrive publishes odom TF" \
    || note "no <tf_topic> found — without it odom→base_link never appears (handbook/12)"
  grep -rqs 'cmd_vel' src/task2 && go "publishes to /cmd_vel" \
    || nogo "nothing references cmd_vel" "Your driving node must publish Twist."
  grep -rqs 'odom' src/task2 && go "uses /odom" \
    || nogo "nothing references odom" "Close the loop on odometry."
  [ "$MFAIL" -eq 0 ] && DONE_LIST="$DONE_LIST 2"
fi

# ──────────────────────────────── TASK 3 ────────────────────────────────
section "TASK 3 — VISION"
MFAIL=0
if ! has_work 3; then
  idle "not started"
else
  STARTED="$STARTED 3"
  find src/task3 -name '*.py' 2>/dev/null | grep -q . && go "sources present" \
    || nogo "no Python under src/task3/" "See the Task 3 sheet."
  grep -rqs 'cv_bridge\|CvBridge' src/task3 && go "cv_bridge used" \
    || nogo "no cv_bridge usage" "Needed to convert ROS images to OpenCV."
  grep -rqs 'aruco\|Aruco\|ArUco' src/task3 && go "marker detection present" \
    || nogo "no ArUco usage" "Marker detection is required."
  grep -rqs 'test_images\|expected.json' src/task3 \
    && go "runs against the provided test images" \
    || nogo "no reference to the test images" "See the Task 3 sheet."
  grep -rqs 'camera_info\|CameraInfo' src/task3 && go "camera intrinsics used" \
    || nogo "no camera_info usage" "Pose estimation needs camera intrinsics."
  grep -rqs 'TransformStamped\|sendTransform\|TransformBroadcaster' src/task3 \
    && go "publishes marker TF" || nogo "no TF broadcast" "Publish the marker as a TF frame."
  [ "$MFAIL" -eq 0 ] && DONE_LIST="$DONE_LIST 3"
fi

# ──────────────────────────────── TASK 4 ────────────────────────────────
section "TASK 4 — NAVIGATION  (bonus)"
if ! has_work 4; then
  idle "not attempted — this costs you nothing"
else
  STARTED="$STARTED 4"
  { [ -f src/task4/OBSERVATIONS.md ] && [ "$(wc -w < src/task4/OBSERVATIONS.md)" -gt 300 ]; } \
    && go "observations written ($(wc -w < src/task4/OBSERVATIONS.md) words)" \
    || note "OBSERVATIONS.md missing or under 300 words"
  find src/task4 -name '*.rviz' 2>/dev/null | grep -q . && go "RViz config committed" || note "no .rviz config"
  find src/task4 \( -name '*.yaml' -o -name '*.pgm' \) 2>/dev/null | grep -q . \
    && go "saved map present" || note "no saved map"
  DONE_LIST="$DONE_LIST 4"   # bonus never fails
fi

# ─────────────────────────────── SUMMARY ───────────────────────────────
printf "\n${B}────────────────────────────────────────${N}\n"
if [ -z "$STARTED" ]; then
  printf "${D}Nothing submitted yet. Nothing to check yet.${N}\n\n"
  exit 0
fi
printf "Started:%s   Complete:%s\n" "${STARTED:-  none}" "${DONE_LIST:-  none}"
if [ "$FAIL" -eq 0 ]; then
  printf "${G}${B}ALL STATIONS GO.${N}\n\n"
else
  printf "${R}${B}HOLD — fix the NO-GO lines above.${N} ${D}(Anything not started is ignored.)${N}\n\n"
  exit 1
fi
