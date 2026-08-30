# 21 — Camera intrinsics

> **Time:** 30 minutes.
> **By the end:** you understand why a flat picture can tell you a distance.

## The question

A camera flattens the 3-D world onto a 2-D sensor. That throws away depth — a
small rock nearby and a large rock far away can produce **identical** pixels.

So how can you possibly get a distance out of one image?

**You can't — unless you know how big the thing is.** If you know the marker is
exactly 15 cm across, and you know how the lens maps the world onto pixels, then
its apparent size tells you its distance. Intrinsics are the second half of that.

## The camera matrix

```bash
ros2 topic echo /camera/camera_info --once
```

```yaml
height: 480
width: 640
k: [554.25, 0.0, 320.5,
    0.0, 554.25, 240.5,
    0.0, 0.0, 1.0]
d: [0.0, 0.0, 0.0, 0.0, 0.0]
```

`k` is the **camera matrix**, usually written K:

```
      ⎡ fx   0   cx ⎤
  K = ⎢  0  fy   cy ⎥
      ⎣  0   0    1 ⎦
```

- **fx, fy — focal length in pixels.** How strongly the lens magnifies. Bigger =
  narrower field of view, things look larger.
- **cx, cy — the optical centre**, where the lens axis meets the sensor. Usually
  near the image centre (here 320.5, 240.5 for a 640×480 image — as expected).

`d` holds **distortion** coefficients, for lenses that bend straight lines. Our
simulated camera is perfect, so they're all zero. A real camera needs calibration
to find them.

## The relationship, in one line

For an object of real size **S** appearing **w** pixels wide at distance **Z**:

```
w = fx · S / Z        which rearranges to        Z = fx · S / w
```

Check it against the numbers above: a 15 cm marker filling 300 pixels with
fx = 600 gives Z = 600 × 0.15 / 300 = **0.30 m**. That's the whole idea. Everything
else is doing it properly in 3-D and for corners rather than widths.

> **This is why intrinsics are not optional.** Without fx you have a ratio and no
> scale — you can say "twice as far as before" but never "1.4 metres".

## Getting them in code

```python
from sensor_msgs.msg import CameraInfo
import numpy as np


class Detector(Node):
    def __init__(self):
        ...
        self.K = None
        self.dist = None
        self.create_subscription(
            CameraInfo, '/camera/camera_info', self.on_info, 10)

    def on_info(self, msg):
        self.K = np.array(msg.k, dtype=np.float64).reshape(3, 3)
        self.dist = np.array(msg.d, dtype=np.float64)
```

Then guard your image callback:

```python
    def on_image(self, msg):
        if self.K is None:
            return          # no intrinsics yet — can't estimate anything
```

`camera_info` is often published less frequently than images, and sometimes only
once. **Store it when it arrives; don't assume it's there.** Not guarding this is
a guaranteed startup crash.

## Frame conventions — the one that will catch you

OpenCV and ROS do not agree on which way a camera points.

| | x | y | z |
|---|---|---|---|
| **OpenCV** (optical) | right | down | **forward** |
| **ROS** (body, REP-103) | forward | left | up |

So a translation of `[0, 0, 2.0]` from OpenCV means *2 m in front of the camera*.
Publish that straight into a ROS frame that follows the body convention and your
marker appears 2 m **above** the rover.

Two ways to handle it:

1. **Convention (recommended).** Name your camera's optical frame
   `camera_optical_frame` and add a fixed joint rotating it from `camera_link`:
   ```xml
   <joint name="camera_optical_joint" type="fixed">
     <parent link="camera_link"/>
     <child link="camera_optical_frame"/>
     <origin xyz="0 0 0" rpy="-1.5708 0 -1.5708"/>
   </joint>
   ```
   Publish detections in `camera_optical_frame` and TF handles the rest. This is
   what ROS expects, and why you see `_optical_frame` everywhere in real stacks.
2. **By hand.** Swap the axes yourself. Works, but you'll get it wrong once and
   it'll take an hour to find.

> If your marker shows up in RViz at roughly the right *distance* but in a
> completely wrong *direction* — this is why. It's the most common Sol 3 bug.

Next: [`22-aruco.md`](22-aruco.md).
