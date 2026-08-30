# 🛰 SOL 4 — "The World Model" · BONUS

> **Optional.** This mission can only add to your evaluation, never subtract.
> Not attempting it costs you nothing.
> **Effort:** 5–7 hours if you take it on.

---

## Mission briefing

Your rover can drive, and it can see. It still has no idea what's *around* it.

A camera looking forward tells you about a cone of the world. To decide where it's
safe to drive, a rover needs something more complete: a model of its surroundings
built from every sensor at once, updated continuously, that a planner can reason
over.

Two ideas do most of the work. **SLAM** — Simultaneous Localisation and Mapping —
builds a map while simultaneously working out where you are in it, each half
depending on the other. And the **costmap**, which turns that map into the only
question a planner actually asks: how expensive is it to be *here*?

This mission is different from the others. **You are not implementing SLAM or
Nav2.** Those are enormous pieces of software and writing either is a year of
work. We give you working configurations. Your job is to run them, look properly
at what they produce, and explain it.

Understanding what these systems do — and where they fail — is worth more to us
right now than a half-working reimplementation.

---

## Tasks

### 1 · Add a LiDAR

📖 [`handbook/30-sensors.md`](../../handbook/30-sensors.md)

Mount a 2-D laser scanner on the rover, bridge it, and visualise the `LaserScan`
in RViz. Drive around and watch the returns move.

### 2 · Add a depth camera and look at a point cloud

📖 [`handbook/30-sensors.md`](../../handbook/30-sensors.md)

Visualise the `PointCloud2`. Colour it by height, then by distance.

A point cloud is exactly what it says — a large set of 3-D points, each measured
off a real surface. Rotate it in RViz until it stops looking like noise and starts
looking like a room. Worth the minute it takes.

### 3 · Learn RViz properly

📖 [`handbook/31-rviz.md`](../../handbook/31-rviz.md)

Most people only ever use RViz by accident. Take an hour and learn it:

- what **Fixed Frame** means, and what happens when it's wrong
- adding, configuring and saving displays
- the TF display, and reading a transform tree visually
- saving a config so you don't rebuild your layout every time

Commit your saved `.rviz` config. A good RViz layout is a genuinely useful thing
to own.

### 4 · Occupancy grids

📖 [`handbook/32-slam-and-nav2.md`](../../handbook/32-slam-and-nav2.md)

An occupancy grid divides the world into cells, each holding one number:

| Value | Meaning |
|---|---|
| `0` | free |
| `100` | occupied |
| `-1` | **unknown** |

That third value matters more than it looks. "I don't know" is different from
"it's clear", and a planner that confuses them will drive somewhere it shouldn't.

### 5 · Run SLAM

📖 [`handbook/32-slam-and-nav2.md`](../../handbook/32-slam-and-nav2.md)

The configuration is in [`sol4_provided/`](../../sol4_provided/). Launch the provided SLAM configuration, drive the rover around your world, and
watch the map assemble itself underneath you.

> **Before you start, confirm these three.** SLAM fails silently — no error, just
> no map — if any is missing:
> ```bash
> ros2 topic hz /scan                        # laser arriving?
> ros2 run tf2_ros tf2_echo odom base_link   # odometry transform present?
> ros2 topic hz /clock                       # simulated time flowing?
> ```
> The middle one is the usual culprit: it needs `<tf_topic>/tf</tf_topic>` on your
> DiffDrive plugin **and** `/tf` bridged. See Sol 2's handbook.

Then save it. You now have a map you made.

### 6 · Run Nav2 and set a goal

Launch the provided navigation stack, click a goal pose in RViz, and watch the
rover plan a path and drive it.

### 7 · Read the costmaps

📖 [`handbook/32-slam-and-nav2.md`](../../handbook/32-slam-and-nav2.md)

Turn on the **global** and **local** costmap displays, plus the global and local
plans. Then work out what you're looking at:

- What are the coloured bands around obstacles, and why are they wider than the
  obstacle?
- Why are there **two** costmaps? What's each one for?
- Why does the local one move with the rover while the global one doesn't?
- What happens to the plan when you put something new in the rover's path?

### 8 · Write it up

This mission's real deliverable is a short document — `src/sol4/OBSERVATIONS.md`,
around 400–600 words — answering, in your own words:

1. What is the difference between the global and local costmap, and why are both
   needed?
2. What do the inflated regions around obstacles represent, and what would break
   if they weren't there?
3. Describe one situation where you made the navigation fail. What did the rover
   do? Why?
4. Occupancy grids represent the world as a flat grid of "free / occupied /
   unknown". Name something real a rover might encounter that this representation
   **cannot express**. What would happen if it drove into one?

> Question 4 is not a trick, and there's more than one good answer. It's an open
> problem the team works on. **Answer it honestly rather than confidently** —
> we're far more interested in how you reason about it than whether you land on
> the answer we have in mind.

**Do not paste documentation.** We can read the docs. We want to know what *you*
understood, and a short honest answer beats a long borrowed one.

---

## Deliverables

| | |
|---|---|
| `src/sol4/OBSERVATIONS.md` | your write-up |
| saved map | the one you built |
| `.rviz` config | your layout |
| screenshot | scan, point cloud, costmap and plan visible at once |
| video | under 90 s — map building, then a goal being driven |

## Checks

```bash
./tools/vanguard check
```
