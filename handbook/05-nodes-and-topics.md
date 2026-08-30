# 05 — Nodes, topics and messages

> **Time:** 45 minutes.
> **By the end:** you can inspect a running robot without reading a line of its code.

## The idea

A robot is not one program. It's dozens of small ones running at once: one talking
to the camera, one to the motors, one planning where to go, one watching the battery.

In ROS each of those is a **node**. Nodes don't call each other. They publish
messages onto named channels called **topics**, and anything interested subscribes.

```
  [camera_node] ──publishes──> /camera/image_raw ──> [detector_node]
                                                └──> [recorder_node]
```

The camera node doesn't know the detector exists. That's the point:

- You can **restart one node** without restarting the robot.
- You can **subscribe to any topic** to see exactly what a node is emitting.
- You can **swap the real camera for a simulated one** and nothing downstream notices.

That last one is why a rover can be developed entirely in simulation and then run
on real hardware unchanged.

## Get something running

Terminal 1:
```bash
ros2 run turtlesim turtlesim_node
```

A window with a turtle. Leave it running.

## Nodes

Terminal 2:
```bash
ros2 node list
```
```
/turtlesim
```

```bash
ros2 node info /turtlesim
```
```
/turtlesim
  Subscribers:
    /turtle1/cmd_vel: geometry_msgs/msg/Twist
  Publishers:
    /turtle1/pose: turtlesim/msg/Pose
    /rosout: rcl_interfaces/msg/Log
  Service Servers:
    /clear: std_srvs/srv/Empty
    /spawn: turtlesim/srv/Spawn
    ...
```

You just read a node's entire interface without opening its source. **Subscribers**
= what it listens to. **Publishers** = what it emits.

The important line: it subscribes to `/turtle1/cmd_vel` expecting
`geometry_msgs/msg/Twist`. To move the turtle, publish that.

## Topics

```bash
ros2 topic list
```
```
/parameter_events
/rosout
/turtle1/cmd_vel
/turtle1/color_sensor
/turtle1/pose
```

### `echo` — watch the traffic

```bash
ros2 topic echo /turtle1/pose
```
```
x: 5.544444561004639
y: 5.544444561004639
theta: 0.0
linear_velocity: 0.0
angular_velocity: 0.0
---
```

Live data, streaming. `Ctrl+C` to stop.

**`ros2 topic echo` is your primary debugging tool.** When something misbehaves,
you don't add print statements — you `echo` the topic and see what's actually on it.

### `info` — who's connected

```bash
ros2 topic info /turtle1/cmd_vel
```
```
Type: geometry_msgs/msg/Twist
Publisher count: 0
Subscriber count: 1
```

**`Publisher count: 0` means nobody is sending.** If a robot isn't moving, this
number tells you instantly whether the problem is upstream (nothing publishing) or
downstream (publishing fine, motors ignoring it).

### `hz` — how fast

```bash
ros2 topic hz /turtle1/pose
```
```
average rate: 62.456
	min: 0.015s max: 0.017s std dev: 0.00051s window: 64
```

Rate matters. A camera meant to run at 30 Hz delivering 4 Hz is a real fault, and
this is how you catch it.

### `pub` — send a message by hand

```bash
ros2 topic pub --rate 1 /turtle1/cmd_vel geometry_msgs/msg/Twist \
  "{linear: {x: 2.0}, angular: {z: 1.8}}"
```

**Watch the turtle move in a circle.** `Ctrl+C` to stop.

You just drove a robot from the command line. In Task 1 you'll write a node that
does this properly — but being able to do it by hand is how you test whether a
problem is in your code or in the robot.

## Messages

```bash
ros2 interface show geometry_msgs/msg/Twist
```
```
Vector3  linear
	float64 x
	float64 y
	float64 z
Vector3  angular
	float64 x
	float64 y
	float64 z
```

A `Twist` is two 3-D vectors: **linear** velocity (m/s) and **angular** velocity
(rad/s). For a ground robot that drives forward and turns, only `linear.x` and
`angular.z` do anything — it can't slide sideways or fly.

> **Conventions worth learning now (REP-103/105):** x is forward, y is left, z is
> up. Angles in radians, distances in metres, counter-clockwise positive. ROS is
> strict about this and it eliminates a whole class of bug.

## See the whole system

```bash
ros2 run rqt_graph rqt_graph
```

A live diagram of every node and topic. With `ros2 topic pub` still running you'll
see it drawn as a box feeding `/turtle1/cmd_vel` into `/turtlesim`.

When you can't work out why two things aren't talking, this picture usually shows
you in one glance — most often a topic name typo, which appears as two boxes with
no line between them.

## The toolkit

| Question | Command |
|---|---|
| What's running? | `ros2 node list` |
| What does this node do? | `ros2 node info /name` |
| What channels exist? | `ros2 topic list` |
| What's on this channel? | `ros2 topic echo /name` |
| Is anyone publishing? | `ros2 topic info /name` |
| How fast? | `ros2 topic hz /name` |
| Send one by hand | `ros2 topic pub /name type "{...}"` |
| What's in this message? | `ros2 interface show <type>` |
| Show me the picture | `rqt_graph` |

Learn these nine. They diagnose most problems you'll hit for the next three years.

Next: [`06-workspace-and-packages.md`](06-workspace-and-packages.md).
