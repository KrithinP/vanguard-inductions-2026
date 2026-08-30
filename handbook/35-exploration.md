# 35 — Frontier exploration

> **By the end:** you know the algorithm well enough to implement it. This page
> deliberately contains **no working code** — describing an algorithm clearly and
> then building it is the skill this task is testing.

## The idea

A **frontier** is the boundary between what you know and what you don't: a cell
you have observed to be **free**, that touches a cell you have **never observed**.

Stand on a frontier and you can see into the unknown. So:

> Drive to a frontier. The map grows. Compute frontiers again. Repeat. When there
> are none left, you have explored everything reachable — and you are done.

That's the whole algorithm. Everything below is making it work.

## The loop

```
1. take the latest map
2. find frontier cells
3. group them into clusters
4. throw away clusters that are too small
5. score the survivors, pick one
6. convert its centre to a world pose
7. send it to Nav2 and wait for the result
8. succeeded or aborted -> back to 1
   no clusters left      -> stop, and say so
```

## Step 2 — finding frontier cells

A cell is a frontier if it is **free** (`0`) **and** at least one of its
neighbours is **unknown** (`-1`).

Choose 4-neighbour or 8-neighbour and be consistent. 8 gives thicker, better
connected frontiers; 4 gives cleaner ones. Either is defensible.

**Do this with array operations, not nested loops.** The trick: build a boolean
array of "is unknown", shift it by one cell in each direction, OR the shifts
together to get "has an unknown neighbour", and AND that with "is free". A few
lines of numpy, and fast enough to run every time the map updates.

## Step 3 — clustering

You now have thousands of individual cells. They are not thousands of
destinations — they're a handful of *regions*, each worth one trip.

Group cells that touch into one cluster. A flood fill or breadth-first search over
the frontier mask is enough; you don't need a library. For each cluster keep its
**size** and its **centroid**.

## Step 4 — throwing things away

Small clusters are usually noise — a stray unknown cell behind a table leg, or
sensor jitter at the edge of the laser's range. Driving to them wastes the whole
run.

Set a minimum cluster size. Somewhere around **10–20 cells** is sensible for a
0.05 m map; tune it and say what you picked. **Too small and your rover chases
ghosts forever; too large and it stops with real territory unexplored.** Both
failures are worth seeing at least once.

## Step 5 — choosing

The obvious rule is **nearest first**. It's simple, it works, and it is not very
good — the rover ping-pongs across the arena as new frontiers open behind it.

Better scores balance competing things:

- **distance** — near is cheap
- **size** — a big frontier reveals more map per trip
- **direction** — one already ahead of you avoids a turn
- **stickiness** — continuing to explore the region you're in beats crossing the
  map for a marginally closer cell

You are not required to do anything clever. **You are required to say what you did
and what's wrong with it.** An honest "I used nearest-first and it ping-pongs
between two corridors" is worth more than a complicated score you can't explain.

## Step 6 — cell to pose

Use the conversion in [`33-occupancy-grids.md`](33-occupancy-grids.md), and
remember the half-cell offset.

**A frontier cell is on the boundary of the unknown, which is often a poor place
to stand.** Nav2 may refuse it, or abort trying. Two common repairs: aim at a
free cell a little way *back* from the frontier, or check the goal has some
clearance from occupied cells before sending it. Both are fair game.

Orientation: face the unknown. Or don't and set `w = 1.0` — but a rover that
arrives facing the wall it just mapped sees nothing new, which is worth thinking
about.

## Step 7 — the failure that will bite you

**A frontier your rover cannot reach will be regenerated every single cycle**,
because failing to get there doesn't observe it, so it stays a frontier forever.

Nearest-first plus no memory equals an infinite loop on the closest unreachable
cell. Your rover will look busy and achieve nothing, and this *will* happen to
you.

Keep a **blacklist** of failed goals and skip anything near one. Decide how near,
and whether entries ever expire — a frontier unreachable now may open up later.

## Step 8 — knowing when to stop

No clusters above your minimum size means done. **Say so**: log it, publish a
final zero velocity, save the map. A robot that quietly keeps spinning has not
finished, it has failed silently.

Guard against the other end too: cap total runtime or total goals, so a bug
can't leave it running all night.

## Watching it work

Publish your frontiers as `visualization_msgs/msg/MarkerArray` and add a
**Marker** display in RViz. Seeing clusters appear, get chosen, and vanish as
they're explored turns this from guesswork into something you can actually debug.

Optional, and the single highest-value hour you can spend on this task.

## When it goes wrong

| Symptom | Usually |
|---|---|
| No frontiers found, ever | Map QoS — you're receiving nothing. See [33](33-occupancy-grids.md) |
| Frontiers everywhere, including inside walls | Free/unknown test inverted, or row/column swapped |
| Rover drives to the same place forever | Unreachable frontier, no blacklist |
| Goals always rejected | Pose in unknown space, bad quaternion, or wrong `frame_id` |
| Explorer stops immediately | Minimum cluster size too high, or map not arrived yet |
| Everything stalls after one goal | Blocking call in a callback — see [34](34-action-clients.md) |
| Node can't keep up | Nested Python loops over the grid. Use numpy |

---

Back to the Task 4 sheet.
