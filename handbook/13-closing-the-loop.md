# 13 — Closing the loop on odometry

> **Time:** 60 minutes.
> **By the end:** your rover drives a square using feedback, and you understand
> why it doesn't come home exactly.

## Open loop vs closed loop

The easy way to drive a square is by timing:

```python
drive_forward(2.0)   # for 4 seconds
turn_left(90)        # for 1.8 seconds
# repeat 4 times
```

This is **open loop** — you issue commands and hope. It will not work well, and
watching it fail is the point of this task.

Wheels slip. The simulator's timestep isn't perfectly uniform. The rover takes a
moment to accelerate. Each error is small; there is nothing to correct them, so
they accumulate. By the fourth corner you're metres and tens of degrees out.

**Closed loop** means looking at where you actually are and reacting:

```python
while distance_travelled < 2.0:
    drive_forward()
```

Still imperfect — `/odom` is itself computed from wheel rotations, so it inherits
wheel slip. But it corrects for timing and acceleration, and it's a large
improvement for very little work.

## Reading `/odom`

```bash
ros2 topic echo /odom --once
```

```yaml
pose:
  pose:
    position:  {x: 1.234, y: 0.056, z: 0.0}
    orientation: {x: 0.0, y: 0.0, z: 0.383, w: 0.924}
twist:
  twist:
    linear:  {x: 0.5, y: 0.0, z: 0.0}
    angular: {z: 0.0, y: 0.0, z: 0.2}
```

- `pose.pose.position` — where it thinks it is, in the `odom` frame
- `pose.pose.orientation` — which way it's facing, as a **quaternion**
- `twist.twist` — how fast it's currently going

## Quaternions, briefly

That orientation is four numbers, not an angle. Quaternions represent 3-D rotation
without the failure modes of Euler angles.

You don't need to understand them today. You need to **convert one to a heading**:

```python
import math

def yaw_from_quaternion(q):
    """Extract rotation about the vertical axis, in radians."""
    siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
    cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
    return math.atan2(siny_cosp, cosy_cosp)
```

`yaw` is your heading: 0 is along +x, π/2 is a quarter turn left. It wraps at ±π,
which matters — see below.

## Angle wrapping

The single most common bug in this task.

Heading runs from −π to +π and **wraps**. If you're at 3.0 rad and your target is
−3.0 rad, the naive difference is 6.0 rad — nearly a full turn the wrong way. The
real difference is about 0.28 rad the other way.

Always normalise:

```python
def normalise(angle):
    """Wrap any angle into [-pi, pi]."""
    return math.atan2(math.sin(angle), math.cos(angle))

error = normalise(target_yaw - current_yaw)
```

Symptom if you skip this: the rover spins nearly all the way round instead of
making a small correction, and only at *some* corners.

## Structuring it

A state machine is the clean approach:

```python
class SquareDriver(Node):
    def __init__(self):
        super().__init__('square_driver')
        self.pub = self.create_publisher(Twist, '/cmd_vel', 10)
        self.sub = self.create_subscription(Odometry, '/odom', self.on_odom, 10)
        self.timer = self.create_timer(0.05, self.control_loop)   # 20 Hz

        self.state = 'DRIVE'        # DRIVE -> TURN -> DRIVE -> ... -> DONE
        self.pose = None
        self.leg = 0
        # record where this leg started, and what heading you want next

    def on_odom(self, msg):
        self.pose = msg.pose.pose         # just store it

    def control_loop(self):
        if self.pose is None:
            return                        # no odometry yet — do nothing
        ...
```

Two things worth copying from that skeleton:

1. **The subscriber only stores data. The timer does the thinking.** Doing control
   inside the odometry callback couples your control rate to your sensor rate and
   makes everything harder to reason about.
2. **Guard against `None`.** Your node starts before the first `/odom` message
   arrives. Not checking is a guaranteed crash on startup.

## Do it properly

- Stop **before** turning, and stop **before** driving. Trying to do both at once
  is a different and harder problem.
- Use a tolerance. `distance == 2.0` will never be exactly true with floats. Use
  `distance >= 2.0` or a small band.
- Send a zero `Twist` when you finish. A node that exits without stopping leaves
  the rover driving off — the last command stands.
- Log each leg with `get_logger().info()` so you can see what it thought it was doing.

## The measurement

When it finishes, compare the final `/odom` position with where it started, and
**write that error in your `MISSION_LOG.md`**:

```
Start:  x=0.000  y=0.000
Finish: x=0.184  y=-0.092
Error:  0.206 m
```

Then try it again with more slip — drive faster, or make the turns sharper — and
see how the error changes.

**That number is the entire reason the next mission exists.** A rover that
navigates only by counting its own wheels gets steadily and confidently lost.
Everything that fixes this involves looking at the outside world.

## If it went wrong

**Rover drives forever** — your stop condition never becomes true. Log the distance
each cycle and watch.

**Spins wildly at corners** — angle wrapping. See above.

**Crashes with `'NoneType' object has no attribute 'position'`** — the first control
tick ran before any odometry arrived. Guard it.

**Drives a rhombus, not a square** — turns are overshooting or undershooting. Slow
the angular velocity down as the heading error gets small, rather than turning at
full speed until you're there.

**Keeps moving after "DONE"** — you never published a zero `Twist`.

---

Back to the Sol 2 sheet.
