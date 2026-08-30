# 33 — Occupancy grids

> **By the end:** you can read a map in code, and convert between grid cells and
> places in the world.

## The message

```bash
ros2 interface show nav_msgs/msg/OccupancyGrid
```

```
std_msgs/Header header
MapMetaData info
  float32 resolution      # metres per cell
  uint32  width           # cells across
  uint32  height          # cells up
  geometry_msgs/Pose origin   # world pose of cell (0,0)
int8[] data               # width*height values, ROW-MAJOR
```

`data` is **one flat list**, not a 2-D array. The cell at column `x`, row `y` is:

```
index = y * width + x
```

Get that backwards and your map is transposed — which looks plausible for a
square arena and wrong for everything else. Sanity-check it early.

## The three values

| Value | Meaning |
|---|---|
| `0` | free — observed, nothing there |
| `100` | occupied — observed, something there |
| `-1` | **unknown** — never observed |

Values in between exist in some maps and mean "probably". slam_toolbox mostly
gives you the three above.

**`-1` is the one this task is built on.** "I have never looked here" is not "it
is clear", and the boundary between `0` and `-1` is exactly what you are hunting.

## Grid ↔ world

Every cell has a real place in the world. You need this in both directions:
frontiers are found in cells, but Nav2 wants a pose in metres.

```
world_x = origin.x + (col + 0.5) * resolution
world_y = origin.y + (row + 0.5) * resolution
```

and back:

```
col = floor((world_x - origin.x) / resolution)
row = floor((world_y - origin.y) / resolution)
```

Three things that catch people:

- **The `+ 0.5`.** Without it you get the cell's corner, not its centre. Half a
  cell of error, every time, in the same direction.
- **`origin` is usually negative**, because SLAM puts the robot near the middle
  and grows the map outward. If you assume the map starts at (0,0) everything
  lands in the wrong place.
- **The map's origin moves.** As slam_toolbox expands the map, `origin` changes
  between messages. Cache a cell index from an old map and it now means somewhere
  else. **Work from the message you were just handed**, not from remembered indices.

## Reading it efficiently

The map is tens of thousands of cells and arrives several times a second. A
double `for` loop in Python over every cell, every message, will not keep up.

```python
import numpy as np
grid = np.array(msg.data, dtype=np.int8).reshape(msg.info.height, msg.info.width)
```

Now you have a proper 2-D array and can ask numpy questions about all of it at
once — `grid == 0`, `grid == -1`, and so on. Neighbour tests become array shifts
rather than nested loops. Work out how to express "free cell next to an unknown
cell" that way; it is the difference between a node that runs at 5 Hz and one
that stalls the whole system.

> **The QoS trap.** `/map` is published **transient local** (latched) — it is sent
> once and held for late subscribers. Subscribe with default QoS and **you will
> receive nothing at all**, with no error. You need:
> ```python
> from rclpy.qos import QoSProfile, QoSDurabilityPolicy, QoSReliabilityPolicy
> qos = QoSProfile(depth=1,
>                  durability=QoSDurabilityPolicy.TRANSIENT_LOCAL,
>                  reliability=QoSReliabilityPolicy.RELIABLE)
> ```
> This costs people hours. From the command line the same thing applies:
> `ros2 topic echo /map --once --qos-durability transient_local`

## Look at it before you trust it

Save a map and open the `.pgm` in any image viewer. White is free, black is
occupied, grey is unknown. If your code disagrees with the picture, the code is
wrong.

Next: [`34-action-clients.md`](34-action-clients.md).
