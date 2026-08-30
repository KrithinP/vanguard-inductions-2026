# 31 — RViz, properly

> **Time:** 45 minutes.
> **By the end:** RViz stops being a thing that mysteriously shows nothing.

Most people use RViz by trial and error for years. An hour spent learning it
properly pays back within a week.

## What RViz is, and isn't

**RViz is not the simulator.** It draws nothing by itself. It subscribes to
topics and renders whatever it finds.

That distinction explains most confusion:

- RViz shows nothing → *nothing is publishing*, or you're not subscribed to it.
- RViz shows something wrong → *the data is wrong*. RViz is an honest window.

Closing RViz doesn't stop the robot. Opening it changes nothing. It is a viewer.

## Fixed Frame — the setting that breaks everything

Top left, under Global Options. It answers: *what should hold still?*

Everything is drawn relative to the Fixed Frame. Choose one that doesn't exist and
**RViz shows nothing at all** and complains about transforms.

| Fixed Frame | You see |
|---|---|
| `base_link` | the world moving around a stationary robot |
| `odom` | the robot driving through a stationary world |
| `map` | same, but corrected by SLAM — needs SLAM running |

**Default is `map`, which doesn't exist until you run SLAM.** That single fact is
the cause of most "RViz is broken" reports. When in doubt, set it to `odom`.

## Displays

**Add** at the bottom left. The ones that matter here:

| Display | Shows | Watch out for |
|---|---|---|
| **RobotModel** | your rover | set *Description Topic* to `/robot_description` |
| **TF** | every frame as axes | turn off *Show Names* once it's crowded |
| **LaserScan** | LiDAR returns | Style → Points, Size → 0.05 |
| **PointCloud2** | depth data | Color Transformer → AxisColor |
| **Map** | the occupancy grid | topic `/map` |
| **Path** | a planned route | one per plan — you'll want two |
| **Costmap** | navigation cost | it's a **Map** display on a costmap topic |
| **Image** | camera feed | inline, no separate window |

Each display has a **Status** line. Green is fine; yellow and red tell you exactly
what's missing. **Read it** — it's more informative than most error messages in ROS.

## Save your layout

Rebuilding this every time is miserable. **File → Save Config As**, into your
package's `rviz/` folder.

Then launch RViz with it already loaded:

```python
Node(
    package='rviz2', executable='rviz2',
    arguments=['-d', os.path.join(pkg, 'rviz', 'rover.rviz')],
)
```

A good `.rviz` config is a genuinely useful thing to own, and **committing one is
part of this mission's deliverables**.

## Interactive tools

Along the top:

- **2D Goal Pose** — click and drag on the map to send Nav2 a destination. Drag
  sets the final heading.
- **2D Pose Estimate** — tell localisation where the robot really is.
- **Publish Point** — click anywhere, get its coordinates on `/clicked_point`.
  Surprisingly handy for measuring things.
- **Measure** — distance between two clicks.

## Reading a costmap

You'll need this in a moment, so here's the key:

| Colour | Meaning |
|---|---|
| dark / transparent | free space |
| blue → cyan → red gradient | rising cost near obstacles (**inflation**) |
| solid black/purple | lethal — a real obstacle |
| grey | **unknown** — never observed |

The coloured halo is wider than the wall on purpose. That's the inflation layer,
and working out *why* it's there is one of the write-up questions.

## If it went wrong

**Completely empty, red errors about transforms** — Fixed Frame. Set it to `odom`.

**RobotModel display is red** — Description Topic isn't `/robot_description`, or
`robot_state_publisher` isn't running.

**Laser scan visible but the robot isn't** — RobotModel display not added, or the
URDF isn't being published.

**Everything flickers or jumps** — two nodes publishing the same transform, or
`use_sim_time` set on some nodes and not others.

**RViz crashes on startup** — graphics. Common in Docker and VMs:
```bash
export LIBGL_ALWAYS_SOFTWARE=1
rviz2
```

Next: [`32-slam-and-nav2.md`](32-slam-and-nav2.md).
