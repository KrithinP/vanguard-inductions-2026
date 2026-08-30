# 32 — SLAM, Nav2 and costmaps

> **Time:** 90 minutes.
> **By the end:** your rover has built a map and driven itself across it, and you
> understand the stack you're about to build on top of.

**This page is about the part you don't write.** SLAM and Nav2 are each years of
work by large teams; the configuration is provided in `vanguard_navigation/`.
Read it, run it, learn to tell when it's misbehaving — then leave it alone.

**Everything else in Sol 4 you write yourself**: the reflex that keeps the rover
alive, the client that commands Nav2, and the logic that decides where to go.
This page is the foundation those sit on, and you will debug them far faster if
you know what a healthy stack looks like first.

## Getting the provided package

```bash
cp -r vanguard_navigation ~/vanguard_ws/src/
cd ~/vanguard_ws && colcon build --symlink-install && source install/setup.bash
```

**Docker users:** already installed — nothing to do.

**Native users:**

```bash
sudo apt install -y ros-jazzy-slam-toolbox ros-jazzy-navigation2 ros-jazzy-nav2-bringup
```

## SLAM

**S**imultaneous **L**ocalisation **A**nd **M**apping. The name states the
circularity: to build a map you must know where you are, and to know where you are
you need a map. SLAM solves both at once, each half constraining the other.

Roughly what happens each scan:

1. Guess where you moved, using odometry.
2. **Scan matching** — slide the new scan against the map until it lines up best.
   That correction is better than the odometry guess.
3. Write the scan into the map at the corrected position.
4. Occasionally recognise somewhere you've been before (**loop closure**) and
   correct all the accumulated drift at once.

Step 4 is why a mapped corridor comes out straight instead of gently curving away.

### Run it

```bash
# Terminal 1 — simulator, rover spawned, bridge running (as before)
# Terminal 2
ros2 launch vanguard_navigation slam.launch.py
# Terminal 3
rviz2
```

In RViz: Fixed Frame `map`, then **Add → Map**, topic `/map`.

Now drive slowly with `teleop_twist_keyboard` and watch. Grey becomes black
(occupied) and white (free) as the LiDAR sweeps.

> **Drive slowly.** Scan matching needs consecutive scans to overlap. Spinning fast
> is the most reliable way to produce a smeared, useless map — and, if you want, a
> good thing to try deliberately once.

Watch the transforms:

```bash
ros2 run tf2_ros tf2_echo map odom
```

That's SLAM's output: the correction between where odometry thinks you are and
where you actually are. It starts near zero and grows as odometry drifts.

### Save the map

```bash
ros2 run nav2_map_server map_saver_cli -f ~/vanguard_ws/arena_map
```

Two files: `arena_map.pgm` (an image — open it, it's just a picture) and
`arena_map.yaml` (resolution, origin, thresholds). **Commit both.**

## Occupancy grids

The map is a grid of cells, each holding one number:

| Value | Meaning |
|---|---|
| `0` | free |
| `100` | occupied |
| `-1` | **unknown** |

That third value carries more weight than it looks. "I have never seen this" is
not "this is clear". A planner that treats unknown as free will happily route
through a wall it hasn't looked at yet.

Look at `allow_unknown: true` in `nav2_params.yaml` and think about what it's
buying and what it's risking.

## Nav2

Nav2 is not one algorithm. It's a set of servers coordinated by a **behaviour tree**:

| Server | Job |
|---|---|
| **planner** | route from here to the goal, over the global costmap |
| **controller** | velocity commands to follow that route, over the local costmap |
| **behaviour** | what to do when stuck — spin, back up, wait |
| **bt_navigator** | runs the tree that decides the order of all of it |

The tree is what makes Nav2 feel intelligent: *plan; follow; if the controller
fails, clear the costmap and retry; if that fails, back up and replan.*

### Lifecycle nodes — the thing that will confuse you

**slam_toolbox and every Nav2 server are *lifecycle* nodes.** They boot into an
`unconfigured` state where they subscribe to nothing, publish nothing, and log
nothing. Something has to walk them through *configure → activate* before they do
any work.

That is why both provided launch files include a `lifecycle_manager`. Without one,
`ros2 node list` shows the node, `ps` shows the process, and **nothing whatsoever
happens** — no error, no warning, no map.

Check the state directly:

```bash
ros2 service call /slam_toolbox/get_state lifecycle_msgs/srv/GetState "{}"
```

```
response: State(id=3, label='active')
```

`label='unconfigured'` means it never started properly. `label='active'` means it's
working. Another quick tell:

```bash
ros2 topic info /scan
```

An active SLAM node appears as `Subscription count: 1`. A count of **0** means
nothing is listening to your laser, however healthy everything looks.

**If anything in this mission silently does nothing, check lifecycle state first.**
It is the single most likely cause, and it produces no error message at the point
you notice the problem.

### Run it

With the simulator and SLAM already running:

```bash
ros2 launch vanguard_navigation nav2.launch.py
```

Wait for the lifecycle manager to report everything active. Then in RViz click
**2D Goal Pose** and drag somewhere on the map.

The rover should plan a route and drive it.

## The costmaps — the part to actually study

Add two **Map** displays in RViz:

- topic `/global_costmap/costmap`
- topic `/local_costmap/costmap`

and two **Path** displays:

- `/plan` — the global route
- `/local_plan` — the controller's short-term trajectory

### Global vs local

|  | Global | Local |
|---|---|---|
| Covers | the whole known map | a 4×4 m window |
| Frame | `map` | `odom` |
| Moves with the robot? | no | **yes** (`rolling_window: true`) |
| Updated | ~1 Hz | ~5 Hz |
| Built from | the saved map + sensors | live sensors only |
| Used by | the planner | the controller |

The split exists because the two jobs have opposite needs. Planning a route across
a building needs breadth and can be slow. Not hitting the chair in front of you
needs speed and only needs to see a few metres. One costmap serving both would be
too slow, too big, or both.

Note the frames too: the local costmap lives in `odom` because the controller needs
**smooth** data — a `map`-frame jump from loop closure would make the rover twitch.

### Inflation

Turn on the costmaps and look at the coloured halo around every obstacle. It's
wider than the obstacle.

That's the **inflation layer**, and it's doing something clever: it grows every
obstacle by the robot's radius, so the planner can pretend the robot is a
dimensionless **point**. Checking "does this point collide" is enormously cheaper
than checking "does this 0.6 × 0.4 m rectangle collide, at this orientation" — and
inflation makes them equivalent.

`inflation_radius: 0.55` with `robot_radius: 0.35` leaves ~0.2 m of margin.

**Try changing it.** Set `inflation_radius` to `0.1`, rebuild, and watch the rover
cut corners and clip obstacles. Set it to `2.0` and watch it refuse to enter a
doorway it fits through easily. That experiment will teach you more than this page.

## Things to break on purpose

Do this **now**, before you write any of Sol 4. Every one of these will happen to
you accidentally later, and recognising it in five seconds instead of an hour is
the entire return on this page:

- Put an obstacle in front of the rover **while** it's driving. Watch the local
  costmap update and the local plan bend around it.
- Set a goal inside a wall.
- Set a goal in grey unknown space.
- Drop `inflation_radius` to 0.1 and drive through a tight gap.
- Spin the rover fast during mapping, then try to navigate the resulting map.
- Drive somewhere, then physically teleport the model in Gazebo. Watch odometry
  and the map disagree.

## If it went wrong

**Map never appears, and slam_toolbox prints nothing at all** — it is almost
certainly stuck in `unconfigured`. Check with the `get_state` call above. If you
launched the node by hand with `ros2 run` instead of using
`ros2 launch vanguard_navigation slam.launch.py`, there is no lifecycle manager and it
will never activate. Use the launch file.

**Map never appears but SLAM is `active`** — Fixed Frame isn't `map`, or it isn't
getting `/scan`. Check `ros2 topic hz /scan` and `ros2 topic info /scan`.

**`maximum laser range setting (25.0 m) exceeds the capabilities of the used Lidar`**
— harmless, but it means `max_laser_range` in the config doesn't match your
sensor's `<range><max>`. Make them agree.

**Map appears then smears into nonsense** — driving too fast, or odometry is bad.

**"2D Goal Pose" does nothing** — Nav2 servers didn't activate. Read the lifecycle
manager log.

**Rover plans a path but doesn't move** — check whether anything reaches `/cmd_vel`
(`ros2 topic echo /cmd_vel`). If the plan exists but no velocities flow, the
controller failed to activate. **Also check the message type.** On our Jazzy stack
(Nav2 1.3.12) `/cmd_vel` is `geometry_msgs/msg/Twist`, which matches the bridge
line from Sol 2 — but newer Nav2 releases switched to `TwistStamped`, and if the
two ends disagree the messages vanish with no error at all. Confirm with:

```bash
ros2 topic info /cmd_vel -v
```

**Rover spins in place forever** — a recovery behaviour is running because the
controller thinks it's stuck. Usually a bad costmap or a goal it can't reach.

**"Timed out waiting for transform map to base_link"** — SLAM isn't publishing, or
`use_sim_time` is inconsistent. It must be `true` everywhere when using Gazebo.

**Everything is unbearably slow** — run Gazebo headless (`gz sim -s`) and watch in
RViz only.

---

Back to the Sol 4 sheet.
