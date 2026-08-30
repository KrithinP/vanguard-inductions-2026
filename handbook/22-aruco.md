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

## Warning: Read this before you copy any tutorial

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

> ### Warning: Textures may not render, and that is not your fault
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

**From here on you write the code.** Sol 1 handed you a working node to copy;
this one gives you the API and the traps, and you assemble it. That step up is
deliberate.

### The calls you need

```python
aruco      = cv2.aruco
dictionary = aruco.getPredefinedDictionary(aruco.DICT_4X4_50)
detector   = aruco.ArucoDetector(dictionary, aruco.DetectorParameters())

corners, ids, rejected = detector.detectMarkers(gray_image)
```

- Build the dictionary and detector **once, in `__init__`**. Rebuilding them per
  frame is wasteful and a common beginner smell.
- `detectMarkers` wants a **grayscale** image. Convert with
  `cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)`.
- `corners` is a list of arrays, one per marker, each `(1, 4, 2)` — four
  (x, y) image points, in order: top-left, top-right, bottom-right, bottom-left.
  **That order matters in the next section.**
- `ids` is an `(N, 1)` array, or **`None`** when nothing is found — not an empty
  list. `if ids is not None:` — `len(ids)` raises.

### The node you're building

Structure it yourself, but it needs to:

- subscribe to the image topic **and** `/camera/camera_info`
- store the intrinsics when they arrive, and **return early from the image
  callback until they have** — camera_info is often published once, and later
  than the first frame
- detect, and log which IDs it saw
- draw the result with `cv2.aruco.drawDetectedMarkers(frame, corners, ids)` and
  publish it, so you can watch it live in `rqt_image_view`

Get detection visible before attempting pose. **Everything after this is debugged
by looking at that image**, so it is worth the twenty minutes.

## Pose estimation

`estimatePoseSingleMarkers` no longer exists. Use `cv2.solvePnP` directly, which
is what it called internally anyway.

**The idea:** you know where the marker's four corners are in *its own*
coordinates — a flat square of known size, centred on itself. You have measured
where those corners landed in the image. `solvePnP` solves for the rotation and
translation that explains the difference.

### What you have to work out

1. **The object points.** Four 3-D points describing the marker's corners in its
   own frame, `z = 0` because it's flat, sized by your real marker. They must be
   in the **same order** `detectMarkers` returns: top-left, top-right,
   bottom-right, bottom-left. Get the order wrong and the pose is a plausible-
   looking lie.
2. **The image points.** `corners[i]` reshaped to `(4, 2)` and cast to `float32`.
3. **The call.** `cv2.solvePnP(object_points, image_points, K, dist, flags=...)`
   returns `(success, rvec, tvec)`. Use **`cv2.SOLVEPNP_IPPE_SQUARE`** — it is
   built for exactly this case and is far more stable than the default.

### Reading the answer

`tvec` is the marker's position **in the camera's optical frame**, in metres:
x right, y down, **z forward**. So `tvec[2]` is how far in front of the camera it
is — that's the number to check first against a tape measure.

`rvec` is a compact axis-angle rotation. `cv2.Rodrigues(rvec)` turns it into a
3×3 matrix when you need one.

Check it visually before you trust it:

```python
cv2.drawFrameAxes(frame, K, dist, rvec, tvec, marker_size / 2)
```

The axes should sit flat **on** the marker. Floating, tilted or scaled wrongly
means your object points are wrong — almost always the order or the size.

## Publishing it as a TF frame

A pose that only exists inside your node isn't much use. Broadcast it so the rest
of ROS — and RViz — can see it.

You'll need a `tf2_ros.TransformBroadcaster`, and to fill a
`geometry_msgs/msg/TransformStamped` with the translation from `tvec` and a
**quaternion** converted from `rvec`. `scipy.spatial.transform.Rotation` will do
the matrix→quaternion step in one line (note it returns **x, y, z, w** — ROS
wants the same order, but check, because half the libraries in this field
disagree). Doing the conversion by hand is about ten lines and a good exercise.

Two details that decide whether this works:

- **Use the image's timestamp**, `msg.header.stamp` — **not** `now()`. The pose
  describes where the marker was when the picture was taken. Using "now" makes TF
  lookups fail or return quietly wrong answers while the rover is moving, and the
  error surfaces nowhere near the cause.
- **`frame_id` must be your camera's optical frame**, not `camera_link`. See
  [`21-intrinsics.md`](21-intrinsics.md). Publishing into the body frame puts the
  marker in a completely wrong direction while the distance still looks right —
  which is exactly how you waste an evening.

Then in RViz: Fixed Frame `odom`, add **TF**, and drive around. **The marker frame
should stay still in the world while the rover moves.** If it slides along with
the rover, your transform is being published in the wrong frame.

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

Back to the Sol 3 sheet.
