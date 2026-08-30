# 30 — LiDAR, depth and point clouds

> **Time:** 45 minutes.
> **By the end:** your rover senses the shape of the world around it.

## Adding a 2-D LiDAR

A laser scanner sweeps a beam around and reports the distance to the first thing
it hits at each angle. One horizontal slice of the world, updated many times a
second. Cheap, fast, reliable — which is why almost every ground robot has one.

```xml
  <link name="lidar_link">
    <visual><geometry><cylinder radius="0.04" length="0.04"/></geometry></visual>
    <inertial><mass value="0.2"/>
      <inertia ixx="1e-4" ixy="0" ixz="0" iyy="1e-4" iyz="0" izz="1e-4"/></inertial>
  </link>

  <joint name="lidar_joint" type="fixed">
    <parent link="base_link"/>
    <child link="lidar_link"/>
    <origin xyz="0.15 0 0.12" rpy="0 0 0"/>
  </joint>

  <gazebo reference="lidar_link">
    <sensor name="lidar" type="gpu_lidar">
      <update_rate>10</update_rate>
      <always_on>true</always_on>
      <topic>scan</topic>
      <gz_frame_id>lidar_link</gz_frame_id>
      <lidar>
        <scan><horizontal>
          <samples>360</samples>
          <resolution>1</resolution>
          <min_angle>-3.14159</min_angle>
          <max_angle>3.14159</max_angle>
        </horizontal></scan>
        <range><min>0.15</min><max>12.0</max><resolution>0.01</resolution></range>
      </lidar>
    </sensor>
  </gazebo>
```

Bridge it:

```bash
/scan@sensor_msgs/msg/LaserScan[gz.msgs.LaserScan
```

> **`gz_frame_id` matters.** It sets the `frame_id` on the outgoing message. If it
> doesn't name a real link in your TF tree, everything downstream — RViz, SLAM,
> Nav2 — refuses to use the scan and the error message won't obviously say why.

### Look at it

RViz → **Add → LaserScan**, topic `/scan`, Fixed Frame `odom`. Turn *Style* to
**Points** and raise *Size* to about 0.05 so you can actually see them.

Drive around. The returns should stay put in the world while the rover moves
through them. If they smear or rotate with the robot, your TF is wrong.

```bash
ros2 topic echo /scan --once | head -20
```

`ranges` is a list of distances, one per angle, starting at `angle_min` and
stepping by `angle_increment`. **Out-of-range readings come back as `inf`**, which
is not a number — `min(ranges)` on raw data gives you `inf` or garbage. Filter first:

```python
valid = [r for r in msg.ranges if msg.range_min < r < msg.range_max]
closest = min(valid) if valid else float('inf')
```

## Depth camera and point clouds

Where LiDAR gives one flat slice, a depth camera gives a distance for **every
pixel** — a dense 3-D snapshot.

```xml
  <gazebo reference="camera_link">
    <sensor name="depth_camera" type="depth_camera">
      <update_rate>10</update_rate>
      <always_on>true</always_on>
      <topic>depth_camera</topic>
      <gz_frame_id>camera_link</gz_frame_id>
      <camera>
        <horizontal_fov>1.047</horizontal_fov>
        <image><width>320</width><height>240</height><format>R_FLOAT32</format></image>
        <clip><near>0.1</near><far>10.0</far></clip>
      </camera>
    </sensor>
  </gazebo>
```

Bridge the point cloud:

```bash
/depth_camera/points@sensor_msgs/msg/PointCloud2[gz.msgs.PointCloudPacked
```

> Keep depth at 320×240 and 10 Hz. Point clouds are big, and under software
> rendering a 640×480 depth camera at 30 Hz will bring the whole simulation to a
> halt. Nothing here needs the resolution.

### Look at it properly

RViz → **Add → PointCloud2**, topic `/depth_camera/points`.

Then spend two minutes on this, because it's worth it:

1. Set **Color Transformer** to `AxisColor` and **Axis** to `Z` — now height is
   colour, and the ground separates from the obstacles.
2. Switch **Axis** to `X` — now colour is distance from the camera.
3. Rotate the view with the mouse.

There's a moment where it stops looking like coloured noise and starts looking
like a room you could walk through. Wait for that moment. It's the difference
between knowing what a point cloud is and understanding it.

## What you now have

| Sensor | Gives you | Costs |
|---|---|---|
| LiDAR | one accurate horizontal slice, 360° | blind above and below that slice |
| Depth camera | dense 3-D, but only where it's pointed | narrow view, noisier, heavy |

Neither is sufficient alone, which is why real rovers carry both. Notice also that
**both only report surfaces they can see.** Nothing tells you about a hole, an
overhang, or what a rock is made of. Hold that thought — the write-up comes back
to it.

## If it went wrong

**No `/scan` topic** — the `gz-sim-sensors-system` plugin is missing from the
world file, or the bridge isn't running. `gz topic -l` shows Gazebo's side.

**Scan appears but RViz shows "No transform"** — `gz_frame_id` doesn't match a
link in your URDF.

**Scan rotates with the robot instead of staying still** — Fixed Frame is
`base_link`. Set it to `odom`.

**Simulation crawls after adding the depth camera** — expected. Lower the
resolution and rate.

**All ranges are `inf`** — the LiDAR is inside your chassis, below `range_min`.
Move it up or out.

Next: [`31-rviz.md`](31-rviz.md).
