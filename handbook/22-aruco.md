# 22 — ArUco markers

> **Time:** 90 minutes.
> **By the end:** your rover recognises markers and knows where they are in 3-D.

## What a fiducial is

A **fiducial marker** is a pattern designed to be easy for a computer to find:
high contrast, a thick black border, and an internal grid encoding an ID number.

**ArUco** markers are square, black-and-white, and come from predefined
*dictionaries*. `DICT_4X4_50` means a 4×4 internal grid with 50 distinct IDs.

Why they matter to us: the **European Rover Challenge** uses ArUco markers for
localisation and path correction in the autonomous navigation task, and on the
maintenance panel. Detecting them is not an exercise — it's the job.

> Smaller dictionaries (4×4) are easier to detect at distance but tolerate less
> error. `DICT_4X4_50` is a sensible default. Don't use a 7×7 dictionary and then
> wonder why nothing is detected from 3 m away.

---

## ⚠ Read this before you copy any tutorial

**OpenCV 5 removed the old ArUco API.** Every blog post, StackOverflow answer and
YouTube tutorial written before 2024 uses functions that **no longer exist**:

| Old (gone — will raise `AttributeError`) | Current |
|---|---|
| `cv2.aruco.Dictionary_get(...)` | `cv2.aruco.getPredefinedDictionary(...)` |
| `cv2.aruco.detectMarkers(img, dict, ...)` | `detector.detectMarkers(img)` on an `ArucoDetector` |
| `cv2.aruco.drawMarker(...)` | `cv2.aruco.generateImageMarker(...)` |
| `cv2.aruco.estimatePoseSingleMarkers(...)` | `cv2.solvePnP(...)` |

If you get `module 'cv2.aruco' has no attribute 'detectMarkers'`, you have copied
a pre-2024 tutorial. That error is *the* signal. Everything below is written
against the API that actually ships with our container.

Check what you have:

```bash
python3 -c "import cv2; print(cv2.__version__); print(hasattr(cv2.aruco,'ArucoDetector'))"
```
```
5.0.0
True
```

---

## Making markers

```python
import cv2
import numpy as np

aruco = cv2.aruco
dictionary = aruco.getPredefinedDictionary(aruco.DICT_4X4_50)

for marker_id in (0, 1, 2, 3):
    img = aruco.generateImageMarker(dictionary, marker_id, 400)
    # a white quiet zone round the edge is REQUIRED for detection
    canvas = np.full((500, 500), 255, np.uint8)
    canvas[50:450, 50:450] = img
    cv2.imwrite(f'marker_{marker_id}.png', canvas)
```

> **The white border is not decoration.** The detector finds markers by looking
> for a black quad against a lighter background. A marker flush to the edge of a
> texture, or on a dark wall, often won't be found at all.

## Putting them in the world

> ### ⚠ Textures may not render, and that is not your fault
>
> Gazebo renders PBR textures through the `ogre2` engine. **With software
> rendering — which is what you get in Docker, and in most VMs — the texture often
> doesn't load and the marker renders as a solid black square.** Gazebo logs no
> error. Detection then finds nothing, correctly, because there is no pattern
> there.
>
> We verified this: on a headless container the marker face renders pure black.
> With a real GPU it generally works.
>
> **So the graded part of this mission does not depend on it.** We ship
> [`markers/test_images/`](../markers/test_images) — six images with known answers
> — and your detector is scored on those. Getting markers rendering in Gazebo is
> the demo, not the grade. If you see a black square, you have not done anything
> wrong; run against the images and say so in your log.

Add a thin box to your `.sdf` world and apply the marker PNG as a texture:

```xml
    <model name="marker_0">
      <static>true</static>
      <pose>3 0 0.5 0 0 0</pose>
      <link name="link">
        <visual name="visual">
          <geometry><box><size>0.02 0.15 0.15</size></box></geometry>
          <material>
            <pbr><metal>
              <albedo_map>materials/textures/marker_0.png</albedo_map>
            </metal></pbr>
          </material>
        </visual>
        <collision name="collision">
          <geometry><box><size>0.02 0.15 0.15</size></box></geometry>
        </collision>
      </link>
    </model>
```

The box is thin in **x** (0.02 m) and 0.15 m square in y–z, so its printed face
already points back down the −x axis at a rover approaching from the origin.
**No yaw rotation is needed** — adding one turns the face side-on and you'll see a
thin black sliver instead of a marker. (We made exactly that mistake while writing
this.)

**Check in the GUI that you can actually see the square face**, before blaming your
detector. Two different problems look similar from the outside:

| What you see | Cause |
|---|---|
| a thin vertical black line | marker is edge-on — remove the rotation |
| a solid black square | the texture didn't load — see the warning above |
| the pattern | you're fine |

Keep the physical size (0.15 m here) written down. You need it for pose estimation
and it must match reality exactly.

## Detecting

```python
import cv2
import numpy as np
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from cv_bridge import CvBridge


class MarkerDetector(Node):
    def __init__(self):
        super().__init__('marker_detector')
        self.bridge = CvBridge()
        self.K = None
        self.dist = None

        aruco = cv2.aruco
        self.dictionary = aruco.getPredefinedDictionary(aruco.DICT_4X4_50)
        self.detector = aruco.ArucoDetector(self.dictionary,
                                            aruco.DetectorParameters())

        self.create_subscription(CameraInfo, '/camera/camera_info',
                                 self.on_info, 10)
        self.create_subscription(Image, '/camera/image_raw',
                                 self.on_image, 10)
        self.debug_pub = self.create_publisher(Image, '/markers/debug', 10)

    def on_info(self, msg):
        self.K = np.array(msg.k, dtype=np.float64).reshape(3, 3)
        self.dist = np.array(msg.d, dtype=np.float64)

    def on_image(self, msg):
        if self.K is None:
            return

        frame = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        corners, ids, _rejected = self.detector.detectMarkers(gray)

        if ids is not None:
            cv2.aruco.drawDetectedMarkers(frame, corners, ids)
            self.get_logger().info(f'saw markers {ids.flatten().tolist()}')

        # to_image_msg() from handbook 20 — cv2_to_imgmsg is broken on OpenCV 5
        self.debug_pub.publish(to_image_msg(frame, 'bgr8', msg.header))
```

Watch `/markers/debug` in `rqt_image_view`. Outlines and ID numbers should appear
over the markers. **Get this working before attempting pose** — seeing the
detection is how you'll debug everything after it.

> `detectMarkers` returns `ids = None` when nothing is found, not an empty array.
> `if ids is not None:` — not `if len(ids):`, which raises.

## Pose estimation

`estimatePoseSingleMarkers` no longer exists. Use `solvePnP` directly, which is
what it did internally anyway.

The idea: you know the marker's four corners in **its own** coordinates (a flat
square of known size), and you've measured where those corners landed in the
image. `solvePnP` solves for the rotation and translation that explains it.

```python
MARKER_SIZE = 0.15   # metres — MUST match the world

# Corners in the marker's own frame, in the order detectMarkers returns them:
# top-left, top-right, bottom-right, bottom-left
OBJECT_POINTS = np.array([
    [-MARKER_SIZE / 2,  MARKER_SIZE / 2, 0.0],
    [ MARKER_SIZE / 2,  MARKER_SIZE / 2, 0.0],
    [ MARKER_SIZE / 2, -MARKER_SIZE / 2, 0.0],
    [-MARKER_SIZE / 2, -MARKER_SIZE / 2, 0.0],
], dtype=np.float32)


def pose_of(self, marker_corners):
    image_points = marker_corners.reshape(4, 2).astype(np.float32)
    ok, rvec, tvec = cv2.solvePnP(
        OBJECT_POINTS, image_points, self.K, self.dist,
        flags=cv2.SOLVEPNP_IPPE_SQUARE)    # the right solver for a planar square
    if not ok:
        return None
    return rvec, tvec
```

`tvec` is the marker's position **in the camera's optical frame**, in metres:
x right, y down, **z forward**. So `tvec[2]` is how far in front of the camera it
is. `rvec` is the rotation as a compact axis-angle vector — turn it into a matrix
with `cv2.Rodrigues(rvec)`.

Draw the axes to check visually:

```python
cv2.drawFrameAxes(frame, self.K, self.dist, rvec, tvec, MARKER_SIZE / 2)
```

Red-green-blue axes should sit on the marker, flat against it. If they float or
point oddly, your `OBJECT_POINTS` order doesn't match the detected corner order.

## Publishing it as a TF frame

```python
from geometry_msgs.msg import TransformStamped
from tf2_ros import TransformBroadcaster
from scipy.spatial.transform import Rotation


# in __init__
self.tf_broadcaster = TransformBroadcaster(self)

# after computing rvec, tvec
t = TransformStamped()
t.header.stamp = msg.header.stamp           # the IMAGE's time, not now()
t.header.frame_id = 'camera_optical_frame'  # optical convention — see handbook 21
t.child_frame_id = f'marker_{marker_id}'

t.transform.translation.x = float(tvec[0])
t.transform.translation.y = float(tvec[1])
t.transform.translation.z = float(tvec[2])

R, _ = cv2.Rodrigues(rvec)
q = Rotation.from_matrix(R).as_quat()       # returns x, y, z, w
t.transform.rotation.x = float(q[0])
t.transform.rotation.y = float(q[1])
t.transform.rotation.z = float(q[2])
t.transform.rotation.w = float(q[3])

self.tf_broadcaster.sendTransform(t)
```

Two details that matter:

- **Use the image's timestamp**, not `self.get_clock().now()`. The pose describes
  where the marker was when the picture was taken. Using "now" makes TF lookups
  fail or return subtly wrong answers while the rover is moving.
- **`frame_id` must be the optical frame.** Publishing into `camera_link` puts your
  marker in the wrong direction — see [`21`](21-intrinsics.md).

`scipy` is available; if you'd rather not add the dependency, convert the rotation
matrix to a quaternion by hand — it's about ten lines and a good exercise.

Then in RViz: set Fixed Frame to `odom`, add **TF**, and drive around. The marker
frame should stay put in the world while the rover moves. **That is the whole
point**: a thing you found in a flat image, correctly placed in 3-D space.

## Scoring your detector — the provided test images

[`markers/test_images/`](../markers/test_images) holds six images with known
answers in `markers/expected.json`:

| Image | Contains |
|---|---|
| `01_single_close` | one marker, straight on |
| `02_single_far` | small and slightly blurred |
| `03_rotated` | rotated in the image plane |
| `04_two_markers` | two at once |
| `05_off_centre` | near the edge, dim lighting |
| `06_none` | **nothing — must return no detections** |

Run your detector over all six and print what it finds. **This is the part we
grade**, because it works identically on every machine regardless of graphics.

`06_none` is not a throwaway. A detector that reports a marker when there isn't
one is worse than useless on a rover — it will send it driving at a rock. Make
sure yours handles `ids is None` rather than crashing or inventing something.

## Measure your error

Park the rover a measured distance from a marker (read the true value from the
world file and `/odom`). Compare with `tvec[2]`.

Record both numbers in your `MISSION_LOG.md`. Then try it at 1 m, 3 m and 5 m —
the error will not be constant, and understanding why is more valuable than a
small number.

## If it went wrong

**`module 'cv2.aruco' has no attribute 'detectMarkers'`**
You copied a pre-2024 tutorial. See the warning at the top.

**`KeyError: 16` from `cv2_to_imgmsg`**
Expected on our stack — `cv_bridge` was built for OpenCV 4, we run OpenCV 5. Use
`to_image_msg` from [`20-cameras.md`](20-cameras.md). Reading *into* OpenCV with
`imgmsg_to_cv2` is fine; only the way back out is affected.

**`A module compiled using NumPy 1.x cannot be run in NumPy 2.x`**
```bash
pip install --user --break-system-packages "numpy<2"
```

**Nothing is ever detected**
In order: is the marker facing the camera? Is there a white border? Is the image
actually arriving (`ros2 topic hz`)? Is the resolution too low, or the marker too
far? View `/markers/debug` — if the picture looks fine to you and still nothing is
found, try moving much closer to confirm the pipeline works at all.

**Detected, but the ID is wrong**
Wrong dictionary. The one you generate with must be the one you detect with.

**Distance is consistently out by a constant factor**
`MARKER_SIZE` doesn't match the world. Distance scales linearly with it.

**Pose flips or jitters wildly between frames**
Normal for a square marker viewed nearly head-on — there are two solutions that
project almost identically. `SOLVEPNP_IPPE_SQUARE` helps; viewing at a slight
angle helps more.

**Marker appears at the right distance but the wrong direction in RViz**
Optical vs body frame convention. [`21`](21-intrinsics.md).

**`Lookup would require extrapolation into the past`**
You used `now()` instead of the image timestamp, or `use_sim_time` is inconsistent
between nodes.

---

Back to [`sols/sol3/README.md`](../sols/sol3/README.md).
