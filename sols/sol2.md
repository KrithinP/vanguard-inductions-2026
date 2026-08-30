# SOL 2 — "Rolling Chassis"

```
╔════════════════════════════════════════════════════════════════╗
║  SOL 014 · LANDING + 13                                        ║
║  SPROSCAPE · staging area                                      ║
║  STATUS: MOBILITY UNTESTED                                     ║
╠════════════════════════════════════════════════════════════════╣
║  Build the chassis. Prove it moves where you tell it.          ║
╚════════════════════════════════════════════════════════════════╝
```

> **This is the brief** — what to build and what to hand in. It links to the
> handbook chapters you'll need as you go.
>
> **The PDF version has the whole task in one file** — this brief plus every
> handbook chapter it depends on, bundled inline: `sols/sol2-rover.pdf`.

> **Objective:** build the rover, put it in the world, and drive it.
> **Effort:** 6–8 hours.

---

## Mission briefing

The flight computer is awake. It has no idea it's attached to a rover.

Before software can drive a vehicle it needs to know what the vehicle *is* — how
long the chassis is, where the wheels sit, which way is forward. That description
is a real file, and every part of the stack reads it: the simulator to build a
body, the visualiser to draw it, the navigation stack to know how wide a gap it
can fit through.

This Sol you describe the rover, spawn it into a simulated world, and put it under
your own control.

---

## Tasks

### 1 · Describe the rover

 [`handbook/10-urdf.md`](../handbook/10-urdf.md)

Write a **URDF** for a four-wheel rover: a chassis, four wheels, four joints.
Sensible dimensions — roughly 0.6 m long, 0.4 m wide, wheels around 0.1 m radius.

Get the frame names right. `base_link` is the rover's body frame and the rest of
ROS assumes it exists.

### 2 · See it before you simulate it

 [`handbook/10-urdf.md`](../handbook/10-urdf.md)

Load it with `robot_state_publisher` and view it in **RViz**. Use
`joint_state_publisher_gui` to drag the wheels around by hand.

This step catches every geometry mistake in about ten seconds, and it costs nothing
to run. Do it before you go near the simulator — debugging a bad URDF inside
Gazebo is far harder than debugging it here.

### 3 · Understand the transform tree

 [`handbook/11-tf.md`](../handbook/11-tf.md)

Inspect it:

```bash
ros2 run tf2_tools view_frames
```

Every frame should connect back to `base_link` with no orphans. A broken TF tree
is the single most common reason "everything looks fine but nothing works".

### 4 · Spawn it into Gazebo Harmonic

 [`handbook/12-gazebo.md`](../handbook/12-gazebo.md)

Put the rover in a world with some ground and a few obstacles.

> **Watch out:** Gazebo Harmonic is *not* Gazebo Classic. Most tutorials you'll
> find online are for Classic and use `gazebo_ros_pkgs` — those instructions will
> not work here. We use `ros_gz_sim`. If a tutorial mentions `gazebo_ros`, it's
> the wrong one.

### 5 · Bridge the topics

 [`handbook/12-gazebo.md`](../handbook/12-gazebo.md)

Gazebo's topics and ROS's topics are separate worlds. `ros_gz_bridge` connects
them, one topic at a time, and you have to say which.

This is the concept that trips people up most this week. Nothing is broken when a
topic doesn't appear in `ros2 topic list` — it just hasn't been bridged.

### 6 · Drive it by hand

Get a differential-drive plugin working so `/cmd_vel` moves the rover and `/odom`
reports where it thinks it is. Then drive it with `teleop_twist_keyboard`.

### 7 · Drive it with your own code

 [`handbook/13-closing-the-loop.md`](../handbook/13-closing-the-loop.md)

Write a node that drives the rover in a **square** — 2 m per side — and returns
roughly to where it started. Register the entry point as `square`.

Use `/odom` to decide when to stop and turn. Driving by timing alone works badly
and you'll see exactly why: wheels slip, and the error compounds every corner.

**In `MISSION_LOG.md`, record how far off the start point you ended up.** That
number is the reason the next mission exists.

### 8 · Mission log

What broke, what you worked out, what still doesn't make sense.

---

## Deliverables

| What | Details |
|---|---|
| `src/sol2/` | rover description, launch files, your driving node |
| screenshot | RViz showing the rover and its TF tree |
| `MISSION_LOG.md` | updated, including your final position error |
| video | under 90 s — rover driving its square in Gazebo |

In the recording, **say out loud why the rover doesn't return exactly to its
starting point.**

## Checks

```bash
./tools/vanguard check
```

## Stuck?

`./tools/vanguard doctor`, then the handbook, then
[open an Issue](../../issues/new/choose).
