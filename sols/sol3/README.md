# 🛰 SOL 3 — "Eyes"

> **Objective:** give the rover a camera, and teach it to recognise where it is
> from what it sees.
> **Effort:** 6–8 hours.

---

## Mission briefing

Your rover drove a square and didn't quite come home. That gap is dead reckoning
failing: wheels slip, and small errors add up with nothing to correct them. Drive
long enough and the rover's belief about its position becomes fiction.

The fix is to look at something you recognise. If you can see a landmark whose
position you know, you can work out where *you* are — no matter how badly the
wheels have been lying to you.

On a real mission those landmarks are **markers**: printed patterns placed at known
points around the site. Spot one, measure where it is relative to you, and your
position snaps back to the truth. The European Rover Challenge — the competition
you'll be flying in 2027 — uses exactly this, with **ArUco markers** for
localisation and path correction.

This Sol, you give the rover eyes.

---

## Tasks

### 1 · Add a camera

📖 [`handbook/20-cameras.md`](../../handbook/20-cameras.md)

Mount a camera on the rover in your URDF and bridge its image topic into ROS.

Verify with `rqt_image_view` and in RViz. If you can see the world from the
rover's point of view, the hard part is done.

### 2 · Understand an image message

A `sensor_msgs/msg/Image` is a flat array of bytes plus a description of how to
interpret it — width, height, and an **encoding** like `rgb8` or `bgr8`.

Getting the encoding wrong gives you a picture with the red and blue channels
swapped. It's a rite of passage. Recognise it fast.

### 3 · ROS images ↔ OpenCV

📖 [`handbook/20-cameras.md`](../../handbook/20-cameras.md)

`cv_bridge` converts between the two. Write a node that subscribes to the camera,
converts to grayscale, and publishes the result on a new topic. View both.

Small, but it proves the whole pipeline before you build anything real on it.

### 4 · Camera intrinsics

📖 [`handbook/21-intrinsics.md`](../../handbook/21-intrinsics.md)

Look at `/camera_info`. Those numbers — focal length and optical centre — describe
how the lens maps the 3-D world onto a flat sensor.

You need them for step 6, because working out *how far away* something is from a
flat picture is impossible without knowing how the picture was made.

### 5 · Detect markers

📖 [`handbook/22-aruco.md`](../../handbook/22-aruco.md)

> ⚠ **OpenCV 5 removed the old ArUco functions.** Almost every tutorial online
> uses `cv2.aruco.detectMarkers(...)`, which no longer exists. The handbook has
> the API that actually works. Read it before you search.

Generate some ArUco markers and write a node that finds them. Two parts:

**a. Against the provided test images — this is the graded part.**
[`markers/test_images/`](../../markers/test_images) holds six images with known
answers. Run your detector over all six and report what it finds. It works the
same on every machine, so nobody is advantaged by hardware.

One of them contains **no marker**. A detector that reports something there is
worse than one that finds nothing — on a real rover it drives you into a rock.

**b. Live in the Gazebo world — the demo.**
Place markers in your world and detect them from the rover's camera. Draw the
outline and ID and publish it so you can watch it happen.

> If the marker renders as a **solid black square** in Gazebo, that's software
> rendering failing to load the texture, not your code. It's common in Docker.
> Say so in your log and lean on part (a). You are not marked down for it.

### 6 · Estimate marker pose

📖 [`handbook/22-aruco.md`](../../handbook/22-aruco.md)

Using the intrinsics, work out **where each marker is relative to the camera** —
distance and orientation, not just presence in the frame.

Publish it as a TF frame. Then look in RViz: the marker should appear in 3-D,
in the right place, moving correctly as the rover drives.

That moment — a thing you detected in a flat image showing up correctly positioned
in 3-D space — is the whole of robotic perception in miniature.

### 7 · Sanity-check yourself

Park the rover a measured distance from a marker. Compare your estimate to the
truth. **Write both numbers in your `MISSION_LOG.md`.**

Be honest about the error. Everyone's is worse than they expect; the ones we're
interested in are the people who measured it and can say *why*.

### 8 · Mission log

---

## Deliverables

| | |
|---|---|
| `src/sol3/` | camera setup, detection node, pose estimation |
| detector output | what your detector found on all six test images |
| screenshot | RViz with marker frames placed in 3-D |
| `MISSION_LOG.md` | updated, including measured vs. estimated distance |
| video | under 90 s — live detection with the rover moving |

In the recording, **say out loud why camera intrinsics are needed to estimate
distance.**

## Checks

```bash
./tools/vanguard check
```
