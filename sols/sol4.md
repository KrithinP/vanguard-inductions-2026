# SOL 4 — "Terra Incognita"

```
╔════════════════════════════════════════════════════════════════╗
║  SOL 067 · LANDING + 66                                        ║
║  TERRA INCOGNITA · unmapped                                    ║
║  STATUS: OPERATOR OUT OF CONTACT                               ║
╠════════════════════════════════════════════════════════════════╣
║  No map. No instructions. Go and find out.                     ║
╚════════════════════════════════════════════════════════════════╝
```

> **This is the brief** — what to build and what to hand in. It links to the
> handbook chapters you'll need as you go.
>
> **The PDF version has the whole task in one file** — this brief plus every
> handbook chapter it depends on, bundled inline: `sols/sol4-autonomy.pdf`.

> **The hard one.** Optional, and it can only add to your evaluation — but this is
> the task that tells us who you are as an engineer.
> **Effort:** 12–18 hours. Do not start this three days before the deadline.

---

## Mission briefing

Your rover can drive, and it can see. It still has to be told where to go.

On Mars nobody tells it. The rover is dropped into terrain no one has mapped,
with a 4–24 minute comms delay, and is expected to **work out for itself where it
has not been yet, and go there.** That is the whole autonomy problem in one
sentence, and by the end of this task you will have solved a version of it.

Three pieces, each one a real capability:

1. **Don't hit things** — a reflex that works from raw laser data with no map at
   all.
2. **Ask the navigation stack for something** — drive to a pose you choose, in
   code, and handle it when that fails.
3. **Decide where to go** — look at a half-built map, find the boundary between
   what you know and what you don't, and send yourself there. Repeatedly, until
   there is nothing left to explore.

**We give you the mapping and navigation infrastructure.** You write the autonomy
on top of it. That split is deliberate and it is how the real stack works: SLAM
and Nav2 are years of other people's engineering, and your job on this team is
the layer that decides what to do with them.

> **How much help you get:** less than in earlier tasks. You get the concepts, the
> message formats, the traps, and the shape of the algorithms. **You do not get
> working code.** Working out the implementation from a clear description is the
> skill being tested.

---

## What you're given

[`vanguard_navigation/`](../vanguard_navigation/) — a working SLAM and Nav2
configuration, launch files included. Read it, run it, don't rewrite it.

```bash
cp -r vanguard_navigation ~/vanguard_ws/src/
cd ~/vanguard_ws && colcon build --symlink-install && source install/setup.bash

ros2 launch vanguard_navigation slam.launch.py   # mapping
ros2 launch vanguard_navigation nav2.launch.py   # navigation
```

 [`handbook/32-slam-and-nav2.md`](../handbook/32-slam-and-nav2.md) explains what
it's doing and how to tell when it isn't.

---

## Part A — Sensing · *warm-up*

Add a **2-D LiDAR** to your rover and bridge it. Add a **depth camera** if you
want the point cloud; it isn't required.

Then learn RViz properly and **commit a saved `.rviz` config** showing the scan,
the robot model and the TF tree at once.

 [`handbook/30-sensors.md`](../handbook/30-sensors.md) ·
[`handbook/31-rviz.md`](../handbook/31-rviz.md)

---

## Part B — A reflex that keeps you alive · *write it yourself*

Write a node that drives the rover forward and **never hits anything**, using
`/scan` only. No map, no Nav2, no global knowledge — just the laser and a
decision, tens of times a second.

Requirements:

- Subscribe to `sensor_msgs/msg/LaserScan`, publish `geometry_msgs/msg/Twist`.
- Run the control loop on a **timer**, not inside the scan callback.
- Handle `inf` and `NaN` returns correctly. They are not distances and
  `min(ranges)` on raw data is a bug.
- Divide the scan into sectors and steer toward open space rather than simply
  stopping. **A rover that stops is not avoiding obstacles, it is refusing to
  work.**
- Slow down as things get closer instead of driving at full speed until a
  threshold trips.
- Never drive backwards into something you cannot see — you have no rear sensor.

**Prove it:** drop the rover in a world with scattered obstacles and let it run
for **two minutes without touching anything**. Record it.

 [`handbook/30-sensors.md`](../handbook/30-sensors.md) for the message format.
The algorithm is yours.

---

## Part C — Commanding the navigation stack · *write it yourself*

Part B has no idea where it is or where it's going. Now use the real stack.

Write a node that sends goals to Nav2's **`NavigateToPose`** action server from
code — not by clicking in RViz.

Requirements:

- An `ActionClient` for `nav2_msgs/action/NavigateToPose`.
- **Wait for the server** before sending anything, and say so if it never appears.
- Send a goal, log the **feedback** (distance remaining) as it arrives, and log
  the **result**.
- Handle all three failure modes distinctly: goal **rejected**, goal **aborted**,
  and goal **succeeded**. They mean different things and a rover that treats them
  alike will lie to you.
- Read a list of waypoints from a file, drive them **in sequence**, and report how
  many were reached out of how many attempted.
- Use the **async** API (`send_goal_async`, `get_result_async`). Blocking calls
  inside a node deadlock it, and finding that out is part of the task.

 [`handbook/34-action-clients.md`](../handbook/34-action-clients.md)

---

## Part D — Deciding where to go · *the real task*

Now the rover chooses for itself.

**Frontier exploration.** A frontier is the boundary between space you know is
free and space you have never observed. Drive to frontiers and your map grows;
run out of frontiers and you have explored everything reachable.

Write a node that:

1. Subscribes to the SLAM map (`nav_msgs/msg/OccupancyGrid` on `/map`).
2. **Finds the frontier cells** — free cells adjacent to unknown cells.
3. **Groups them into clusters**, because a thousand individual cells is not a
   thousand places to go. Discard clusters too small to be worth the trip.
4. **Picks one.** Nearest is the obvious choice and it is not the best one — say
   in your write-up what you chose and why.
5. Converts that cell to a **world pose** and dispatches it using your Part C
   client.
6. **Repeats** when the goal completes, and **stops cleanly** when no frontiers
   remain.

Requirements:

- Handle the goal being **aborted** — an unreachable frontier must not deadlock
  the loop or be retried forever.
- Do not re-send a frontier you have already failed to reach.
- Log each decision: how many frontiers, which you chose, why.
- **Terminate.** A robot that never decides it is finished is not autonomous.

**Prove it:** start with a blank map and let it explore your arena unattended
until it stops. Record it, and save the resulting map.

 [`handbook/33-occupancy-grids.md`](../handbook/33-occupancy-grids.md) —
grid↔world coordinates, and what the cell values mean
 [`handbook/35-exploration.md`](../handbook/35-exploration.md) — the algorithm,
described

---

## Part E — Write it up · *short*

`src/sol4/NOTES.md`, 300–500 words. Not an essay:

1. **How did you pick which frontier to go to, and what's wrong with your choice?**
2. **What happens when Nav2 aborts a goal?** Describe what your code does and why.
3. **Occupancy grids represent the world as free / occupied / unknown.** Name
   something real a rover would meet that this **cannot represent**, and what
   would happen if it drove into one.
4. **What broke, and how did you find it?**

Question 3 is an open problem the team works on. There is no answer key —
reasoning honestly beats sounding confident.

---

## Deliverables

| What | Details |
|---|---|
| `src/sol4/` | your avoidance node, action client, and explorer |
| `src/sol4/NOTES.md` | the write-up |
| `.rviz` config | your saved layout |
| saved map | the one your rover built by itself |
| video | under 90 s — the rover exploring unattended, and stopping |

In the recording, **say out loud how your code decides where to go next.**

## Checks

```bash
./tools/vanguard check
```

Sol 4 never fails your build — it reports only. It is a bonus.
