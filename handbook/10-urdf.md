# 10 — Describing a robot (URDF)

> **Time:** 60–90 minutes.
> **By the end:** you have a four-wheel rover you can see and move in RViz.

## What a URDF is

A **URDF** (Unified Robot Description Format) is an XML file that says what your
robot is made of. Nothing more — it's a description, not a program.

But almost everything reads it: RViz to draw the robot, the simulator to give it
mass and collision, the navigation stack to know how wide it is, the transform
system to work out where each part is relative to every other part.

Get this file right and a lot of things start working for free. Get it wrong and
you'll chase phantom bugs in code that isn't broken.

## Two ideas: links and joints

- A **link** is a rigid body. The chassis is a link. Each wheel is a link.
- A **joint** connects two links and says how they may move relative to each other.

That's it. A robot is links connected by joints, forming a tree.

```
        base_link  (the chassis)
        /   |   |   \
   wheel_fl |   |  wheel_rr
       wheel_fr wheel_rl
```

Every robot has exactly **one root link** and no loops.

## Your first link

```xml
<?xml version="1.0"?>
<robot name="vanguard_rover">

  <link name="base_link">
    <visual>
      <geometry>
        <box size="0.6 0.4 0.15"/>
      </geometry>
      <material name="rover_grey">
        <color rgba="0.6 0.6 0.6 1.0"/>
      </material>
    </visual>
  </link>

</robot>
```

A link can have three parts, and they do different jobs:

| Tag | Purpose | Who reads it |
|---|---|---|
| `<visual>` | what it looks like | RViz, the simulator's renderer |
| `<collision>` | what it bumps into | the physics engine |
| `<inertial>` | mass and how it's distributed | the physics engine |

**In RViz you only need `<visual>`.** For simulation you need all three, and this
catches people out: a link with no `<inertial>` may be ignored by physics entirely,
so your rover falls through the floor or refuses to move.

> **`base_link` is not just a name we picked.** Large parts of ROS assume a link
> called `base_link` exists and is the robot's body frame. Call it something else
> and tools will quietly fail to find your robot.

## Adding a wheel

```xml
  <link name="wheel_fl">
    <visual>
      <geometry>
        <cylinder radius="0.1" length="0.05"/>
      </geometry>
      <material name="wheel_black">
        <color rgba="0.1 0.1 0.1 1.0"/>
      </material>
    </visual>
  </link>

  <joint name="wheel_fl_joint" type="continuous">
    <parent link="base_link"/>
    <child link="wheel_fl"/>
    <origin xyz="0.2 0.225 -0.05" rpy="-1.5708 0 0"/>
    <axis xyz="0 0 1"/>
  </joint>
```

Reading the joint:

- **`type="continuous"`** — rotates forever about one axis. That's a wheel.
  (Other types: `revolute` rotates but with limits; `fixed` doesn't move at all;
  `prismatic` slides.)
- **`<parent>` / `<child>`** — the joint's direction in the tree. The child moves
  with the parent.
- **`<origin xyz="...">`** — where the child sits relative to the parent, in metres.
  Here: 0.2 m forward, 0.225 m left, 0.05 m down.
- **`rpy="-1.5708 0 0"`** — roll, pitch, yaw in **radians**. A cylinder is created
  standing upright, so it needs rotating a quarter turn (−π/2 ≈ −1.5708) to lie
  like a wheel.
- **`<axis xyz="0 0 1">`** — which axis it spins about, *in the child's own frame*.

> **Everything is metres and radians.** Type `90` where you meant `1.5708` and your
> wheel ends up pointing at the sky. Radians is a ROS-wide convention (REP-103) and
> it never changes.

## Directions

Facing the same way the robot faces:

- **x** is forward
- **y** is left
- **z** is up

So the front-left wheel is at positive x, positive y. The rear-right is negative x,
negative y. Work the four out on paper before typing them — it's much faster than
discovering it in RViz.

## Viewing it

Two nodes do this. **`robot_state_publisher`** reads the URDF and publishes where
every link is. **`joint_state_publisher_gui`** gives you a slider per joint so you
can move them by hand.

Write a launch file — `launch/display.launch.py`:

```python
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    pkg = get_package_share_directory('vanguard_rover')
    urdf = os.path.join(pkg, 'urdf', 'rover.urdf')

    with open(urdf, 'r') as f:
        robot_description = f.read()

    return LaunchDescription([
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            parameters=[{'robot_description': robot_description}],
        ),
        Node(
            package='joint_state_publisher_gui',
            executable='joint_state_publisher_gui',
        ),
        Node(
            package='rviz2',
            executable='rviz2',
        ),
    ])
```

> **`setup.py` must install your URDF and launch files** or the launch file won't
> find them. Add to `data_files`:
> ```python
> import os
> from glob import glob
> ...
> (os.path.join('share', package_name, 'urdf'),   glob('urdf/*')),
> (os.path.join('share', package_name, 'launch'), glob('launch/*.py')),
> ```
> Forgetting this produces `FileNotFoundError` on a file you can plainly see on
> disk — because `ros2 launch` reads from `install/`, not from your source tree.

Then:

```bash
cd ~/vanguard_ws && colcon build --symlink-install && source install/setup.bash
ros2 launch vanguard_rover display.launch.py
```

In RViz:
1. Set **Fixed Frame** to `base_link` (it defaults to `map`, which doesn't exist yet
   — that's the "nothing is showing up" cause 90% of the time).
2. **Add** → **RobotModel**, then set its *Description Topic* to `/robot_description`.
3. **Add** → **TF** to see the frames.

Drag the sliders. The wheels should spin in place.

## Check it before you trust it

```bash
check_urdf $(ros2 pkg prefix vanguard_rover)/share/vanguard_rover/urdf/rover.urdf
```
```
robot name is: vanguard_rover
---------- Successfully Parsed XML ---------------
root Link: base_link has 4 child(ren)
    child(1):  wheel_fl
    ...
```

If it doesn't parse, nothing downstream will work. Fix it here.

## If it went wrong

**RViz is empty and RobotModel says "No transform from [x] to [map]"**
Fixed Frame is `map`. Change it to `base_link`.

**Wheels in the wrong place or pointing oddly**
`rpy` is radians, and `<axis>` is in the *child's* frame, not the world's. Change
one number at a time and watch.

**`Error: Failed to build tree` / `parent link not found`**
A joint references a link that doesn't exist, or is spelled differently. Typos in
link names are the usual cause. `check_urdf` names the offender.

**Everything is at the origin, stacked on top of each other**
Your joints have no `<origin>`, so every child sits exactly on its parent.

Next: [`11-tf.md`](11-tf.md).
