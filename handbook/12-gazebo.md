# 12 — Gazebo Harmonic and the bridge

> **Time:** 90 minutes.
> **By the end:** your rover exists in a simulated world and moves when you tell it to.

## Warning: Read this before you search the internet

There are **two** Gazebos, and almost everything written online is about the wrong one.

| | Gazebo **Classic** | Gazebo **Harmonic** |
|---|---|---|
| Status | end of life (Jan 2025) | current, what we use |
| Commands | `gazebo`, `rosrun gazebo_ros` | `gz sim` |
| ROS packages | `gazebo_ros_pkgs`, `gazebo_ros` | `ros_gz_sim`, `ros_gz_bridge` |
| Plugin names | `libgazebo_ros_diff_drive.so` | `gz-sim-diff-drive-system` | **If a tutorial mentions `gazebo_ros`, `libgazebo_ros_*.so`, or tells you to run
`gazebo`, it is for Classic and will not work here.** This will happen constantly.
Check before you spend an hour on it.

The tell: Classic tutorials are usually written for ROS Melodic, Noetic or Foxy.
We're on **Jazzy**, which pairs with **Harmonic**.

## Two separate worlds

This is the concept for this week, so slow down here.

Gazebo has its own messaging system — its own topics, its own message types —
completely separate from ROS. They are two different programs that do not
automatically understand each other.

```
  Gazebo world                     ROS world
  ────────────                     ─────────
  /model/rover/cmd_vel   ←──┐  ┌──→  /cmd_vel
  gz.msgs.Twist             │  │     geometry_msgs/msg/Twist
                        [ ros_gz_bridge ]
```

A **bridge** connects one topic to one topic, translating the message type. Nothing
crosses unless you explicitly bridge it.

> **This explains the confusion you're about to have.** You'll start the simulator,
> run `ros2 topic list`, and not see your robot's topics. Nothing is broken. They
> simply haven't been bridged yet.

## Check your install

```bash
gz sim --version
```
```
Gazebo Sim, version 8.x.x
```

Version 8 is Harmonic. If this command isn't found:

```bash
sudo apt install -y ros-jazzy-ros-gz
```

Try an empty world:

```bash
gz sim empty.sdf
```

Press the **▶ play** button at the bottom left. If the window opens and time
advances, you're in business. Close it.

> On slow machines add `-s` to run headless (no GUI) and `-v 4` for verbose logging.

## A world to drive in

Worlds are **SDF** files — similar to URDF, but for whole scenes. Create
`worlds/arena.sdf`:

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <world name="arena">

    <plugin filename="gz-sim-physics-system"
            name="gz::sim::systems::Physics"/>
    <plugin filename="gz-sim-user-commands-system"
            name="gz::sim::systems::UserCommands"/>
    <plugin filename="gz-sim-scene-broadcaster-system"
            name="gz::sim::systems::SceneBroadcaster"/>

    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <direction>-0.5 0.1 -0.9</direction>
    </light>

    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry><plane><normal>0 0 1</normal><size>100 100</size></plane></geometry>
        </collision>
        <visual name="visual">
          <geometry><plane><normal>0 0 1</normal><size>100 100</size></plane></geometry>
          <material><ambient>0.6 0.4 0.3 1</ambient><diffuse>0.6 0.4 0.3 1</diffuse></material>
        </visual>
      </link>
    </model>

  </world>
</sdf>
```

> Those three `<plugin>` lines are not optional. Without **Physics** nothing moves;
> without **SceneBroadcaster** you see an empty window even though the world loaded.

Add a few obstacle boxes yourself — you'll want them later.

## Making the rover physical

Your earlier URDF only had `<visual>`. Physics needs mass and collision on **every**
link:

```xml
  <link name="base_link">
    <visual>...</visual>

    <collision>
      <geometry><box size="0.6 0.4 0.15"/></geometry>
    </collision>

    <inertial>
      <mass value="10.0"/>
      <inertia ixx="0.15" ixy="0.0" ixz="0.0"
               iyy="0.32" iyz="0.0" izz="0.42"/>
    </inertial>
  </link>
```

The inertia numbers matter less than their being *present and non-zero*. For a box
of mass *m*, width *w*, depth *d*, height *h*:

```
ixx = m(d² + h²)/12     iyy = m(w² + h²)/12     izz = m(w² + d²)/12
```

> **A link with no `<inertial>` is ignored by physics.** The classic symptoms: the
> rover falls through the ground, explodes on spawn, or simply refuses to move.
> If that happens, check every link has mass before you suspect anything else.

## The drive plugin

Add this inside `<robot>`, at the end:

```xml
  <gazebo>
    <plugin filename="gz-sim-diff-drive-system"
            name="gz::sim::systems::DiffDrive">
      <left_joint>wheel_fl_joint</left_joint>
      <left_joint>wheel_rl_joint</left_joint>
      <right_joint>wheel_fr_joint</right_joint>
      <right_joint>wheel_rr_joint</right_joint>
      <wheel_separation>0.45</wheel_separation>
      <wheel_radius>0.1</wheel_radius>
      <odom_publish_frequency>50</odom_publish_frequency>
      <topic>cmd_vel</topic>
      <odom_topic>odom</odom_topic>
      <frame_id>odom</frame_id>
      <child_frame_id>base_link</child_frame_id>
      <tf_topic>/tf</tf_topic>
    </plugin>
  </gazebo>
```

> **Warning —** `<tf_topic>` is easy to miss and breaks everything downstream.** Without it
> the plugin publishes the `/odom` *message* but never the `odom` → `base_link`
> **transform**. Your rover will drive, and `ros2 topic echo /odom` will look
> perfectly healthy — but RViz can't place the robot and anything needing to know
> where it is quietly fails. Bridge `/tf` as well (below), then check with:
>
> ```bash
> ros2 run tf2_ros tf2_echo odom base_link
> ```

Four wheels, two per side — that's **skid steering**, the same way a tank turns.
Listing two `<left_joint>` entries drives both left wheels together.

`wheel_separation` is the distance between the left and right wheel *centres*.
Get it wrong and the rover turns at the wrong rate — worth measuring against your
URDF rather than guessing.

## Spawning

`ros_gz_sim`'s `create` node puts a robot into a running world:

```bash
# Terminal 1
gz sim worlds/arena.sdf

# Terminal 2
ros2 run robot_state_publisher robot_state_publisher \
  --ros-args -p robot_description:="$(cat urdf/rover.urdf)"

# Terminal 3
ros2 run ros_gz_sim create -topic robot_description -z 0.2
```

`-z 0.2` drops it slightly above the ground so it settles rather than starting
intersecting the floor.

Do this properly in a launch file once it works — three terminals gets old fast.

## The bridge

Now connect the two worlds. The syntax is:

```
/topic_name@ros_message_type@gz_message_type
```

and the middle symbol sets direction:

| Symbol | Direction |
|---|---|
| `@` | both ways |
| `[` | Gazebo → ROS (read a sensor) |
| `]` | ROS → Gazebo (send a command) |

```bash
ros2 run ros_gz_bridge parameter_bridge \
  /cmd_vel@geometry_msgs/msg/Twist]gz.msgs.Twist \
  /odom@nav_msgs/msg/Odometry[gz.msgs.Odometry \
  /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock \
  /tf@tf2_msgs/msg/TFMessage[gz.msgs.Pose_V
```

Read the first line as: *commands go from ROS into Gazebo*. The second: *odometry
comes from Gazebo into ROS*.

Now:

```bash
ros2 topic list
```

`/cmd_vel` and `/odom` should be there. **They weren't before the bridge, and
nothing was wrong.**

> **`/clock` matters more than it looks.** Simulated time doesn't run at wall-clock
> speed. Bridge `/clock` and set `use_sim_time: true` on your nodes, or timestamps
> disagree and TF starts complaining about extrapolation.

## Drive it

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

Keys are printed on screen. **That terminal must have focus** for keys to register.

Watch what it's doing:

```bash
ros2 topic echo /cmd_vel
ros2 topic echo /odom --once
ros2 topic hz /odom
```

## If it went wrong

**`gz: command not found`** — `sudo apt install -y ros-jazzy-ros-gz`

**World opens but is empty** — missing the `SceneBroadcaster` plugin, or the file
path is wrong. Run with `-v 4` and read the log.

**Nothing moves, ever** — press ▶ play. The simulator starts paused.

**Rover falls through the floor / explodes on spawn** — a link is missing
`<inertial>` or `<collision>`, or a mass is zero.

**`ros2 topic list` doesn't show `/cmd_vel`** — not bridged, or the bridge exited.
Look at the bridge's own terminal for errors.

**Bridge runs but the rover ignores commands** — the topic names don't line up.
`ros2 topic echo /cmd_vel` proves messages are leaving ROS; then check
`gz topic -l` to see what Gazebo is actually listening on.

**Rover shudders, drifts or slides on its own** — usually inertia values wildly
inconsistent with the masses, or wheel friction. Try a heavier chassis first.

**Everything is extremely slow** — expected under software rendering (all Docker
users). Try `gz sim -s` (headless) and watch in RViz instead.

Next: [`13-closing-the-loop.md`](13-closing-the-loop.md).
