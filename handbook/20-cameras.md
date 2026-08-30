# 20 — Cameras in simulation

> **Time:** 60 minutes.
> **By the end:** your rover has a camera, and you can see what it sees.

## Mounting it

A camera is a link like any other, plus a Gazebo sensor. Add to your URDF:

```xml
  <link name="camera_link">
    <visual>
      <geometry><box size="0.03 0.08 0.03"/></geometry>
      <material name="lens"><color rgba="0.1 0.1 0.1 1"/></material>
    </visual>
    <inertial>
      <mass value="0.1"/>
      <inertia ixx="1e-4" ixy="0" ixz="0" iyy="1e-4" iyz="0" izz="1e-4"/>
    </inertial>
  </link>

  <joint name="camera_joint" type="fixed">
    <parent link="base_link"/>
    <child link="camera_link"/>
    <origin xyz="0.3 0 0.12" rpy="0 0 0"/>
  </joint>

  <gazebo reference="camera_link">
    <sensor name="rover_camera" type="camera">
      <update_rate>30</update_rate>
      <always_on>true</always_on>
      <topic>camera/image_raw</topic>
      <camera>
        <horizontal_fov>1.047</horizontal_fov>
        <image><width>640</width><height>480</height><format>R8G8B8</format></image>
        <clip><near>0.05</near><far>50.0</far></clip>
      </camera>
    </sensor>
  </gazebo>
```

Note `type="fixed"` — the camera is bolted on, it doesn't move independently.

`horizontal_fov` is in **radians**. 1.047 ≈ 60°.

You also need the sensors system in your world file, or no sensor produces anything:

```xml
    <plugin filename="gz-sim-sensors-system"
            name="gz::sim::systems::Sensors">
      <render_engine>ogre2</render_engine>
    </plugin>
```

> Under software rendering (Docker, most VMs) `ogre2` can be slow or unstable. If
> the simulator crashes on start, try `<render_engine>ogre</render_engine>`, and
> drop the camera to 320×240 at 10 Hz. A lower-resolution camera that runs beats a
> high-resolution one that doesn't.

## Bridging it

Images and camera info both need bridging:

```bash
ros2 run ros_gz_bridge parameter_bridge \
  /camera/image_raw@sensor_msgs/msg/Image[gz.msgs.Image \
  /camera/camera_info@sensor_msgs/msg/CameraInfo[gz.msgs.CameraInfo
```

Both are `[` — Gazebo to ROS. You read from a camera; you don't write to it.

> Images are large. For high rates, `ros_gz_image`'s `image_bridge` is more
> efficient than `parameter_bridge`. At 640×480/30 Hz either is fine.

## Looking at it

```bash
ros2 run rqt_image_view rqt_image_view
```

Pick `/camera/image_raw` from the dropdown. You should see the world from the
rover's point of view. Drive it and watch the picture move.

In RViz: **Add → Image**, set the topic. Handy because you get the camera and the
3-D view side by side.

Sanity checks:

```bash
ros2 topic hz /camera/image_raw     # should be near your update_rate
ros2 topic echo /camera/camera_info --once
```

## What an image message actually is

```bash
ros2 interface show sensor_msgs/msg/Image
```

```
std_msgs/Header header      # timestamp + which frame it was taken in
uint32 height               # rows
uint32 width                # columns
string encoding             # what the bytes mean, e.g. "rgb8"
uint8 is_bigendian
uint32 step                 # bytes per row
uint8[] data                # the pixels, one flat array
```

So an image is **a flat array of bytes plus instructions for interpreting it**.
`data` has no structure of its own — `height`, `width`, `step` and `encoding` are
what turn it back into a picture.

### Encodings, and the classic bug

| Encoding | Meaning |
|---|---|
| `rgb8` | 3 bytes per pixel, red-green-blue |
| `bgr8` | 3 bytes per pixel, **blue-green-red** |
| `mono8` | 1 byte per pixel, grayscale |
| `32FC1` | one 32-bit float per pixel (depth, in metres) | **OpenCV uses BGR. ROS commonly publishes RGB.** Get it backwards and everything
red looks blue. It's a rite of passage — the useful part is recognising it in one
second instead of debugging your detector for an hour.

## `cv_bridge`

`cv_bridge` converts between ROS `Image` messages and OpenCV arrays.

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2

class Grayscaler(Node):
    def __init__(self):
        super().__init__('grayscaler')
        self.bridge = CvBridge()
        self.sub = self.create_subscription(
            Image, '/camera/image_raw', self.on_image, 10)
        self.pub = self.create_publisher(Image, '/camera/image_gray', 10)

    def on_image(self, msg):
        # ROS message -> OpenCV array. 'bgr8' is what OpenCV expects.
        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Back to a ROS message. Note we do NOT use cv_bridge here — see below.
        # Keep the original header so the timestamp and frame_id survive; TF
        # needs them later.
        self.pub.publish(to_image_msg(gray, 'mono8', msg.header))

def main(args=None):
    rclpy.init(args=args)
    node = Grayscaler()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
```

## Publishing an image back — and a trap

You'd expect `cv_bridge` to convert both ways. It doesn't, on our stack:

| Direction | Function | Works? |
|---|---|---|
| ROS → OpenCV | `imgmsg_to_cv2` |  yes |
| OpenCV → ROS | `cv2_to_imgmsg` | **`KeyError: 16`** |

`cv_bridge` ships with ROS 2 Jazzy and was built for OpenCV 4. Our OpenCV is 5,
which renumbered its internal type constants, so `cv2_to_imgmsg` can't map them
and raises `KeyError`. Nothing you did is wrong.

The fix is five lines, and it's worth writing once because it shows you exactly
what an `Image` message is:

```python
from sensor_msgs.msg import Image

def to_image_msg(array, encoding, header):
    """numpy array -> sensor_msgs/Image, without cv_bridge.

    Works because an Image message is just the raw bytes plus the numbers
    needed to interpret them: height, width, encoding and step.
    """
    msg = Image()
    msg.header = header
    msg.height = array.shape[0]
    msg.width = array.shape[1]
    msg.encoding = encoding
    msg.is_bigendian = 0
    channels = 1 if array.ndim == 2 else array.shape[2]
    msg.step = array.shape[1] * channels * array.itemsize
    msg.data = array.tobytes()
    return msg
```

`step` is bytes per row. Get it wrong and your image comes out skewed diagonally —
which is a memorable way to learn what `step` means.

Two habits worth forming now:

1. **Always pass `desired_encoding`.** It converts for you, so your code doesn't
   depend on what the publisher happened to choose.
2. **Copy the header onto anything you publish.** Losing the timestamp and
   `frame_id` breaks TF lookups downstream, and the failure appears far from the cause.

Once it runs, view both topics in `rqt_image_view` side by side. Small, but it
proves your whole pipeline works before you build anything real on it.

## If it went wrong

**No image topic at all** — the sensors system plugin is missing from the world, or
the sensor isn't attached to a real link. Run `gz topic -l` to see what Gazebo has.

**Topic exists but nothing arrives** — the bridge direction is wrong. It must be
`[` (Gazebo→ROS).

**Simulator crashes when the camera loads** — rendering. Try `ogre` instead of
`ogre2`, and lower the resolution.

**`ImportError: No module named cv_bridge`** — `sudo apt install ros-jazzy-cv-bridge`

**A wall of text about "a module compiled using NumPy 1.x cannot be run in
NumPy 2.x"** — your NumPy got upgraded past what `cv_bridge` was built against.
Fix and re-check:
```bash
pip install --user --break-system-packages "numpy<2"
python3 -c "import numpy; print(numpy.__version__)"   # must start with 1.
```
`./tools/vanguard doctor` checks this too.

**`KeyError: 16` from `cv2_to_imgmsg`** — expected. Use `to_image_msg` above.

**Colours inverted** — RGB vs BGR. See above.

**Very low frame rate** — expected under software rendering. Drop to 320×240 and
10 Hz; nothing in this mission needs more.

Next: [`21-intrinsics.md`](21-intrinsics.md).
