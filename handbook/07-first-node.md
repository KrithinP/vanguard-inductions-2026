# 07 — Writing your first node

> **Time:** 45 minutes.
> **By the end:** you understand every line of a ROS 2 publisher, and you're ready
> to write your own.

This page walks through a **different** node than the one you have to submit. Read
it, run it, understand it — then write yours. Copying this one won't get you there,
and it isn't meant to.

## The example: a node that says hello

Create the file:

```bash
cd ~/vanguard_ws/src/first_light/first_light
nano hello.py
```

```python
import rclpy                        # the ROS 2 Python library
from rclpy.node import Node         # base class for every node
from std_msgs.msg import String     # the message type we'll send


class HelloPublisher(Node):
    def __init__(self):
        super().__init__('hello_publisher')     # this node's name on the graph

        # Create a publisher: (message type, topic name, queue depth)
        self.publisher_ = self.create_publisher(String, 'greeting', 10)

        # Call self.tick() every 0.5 s — that's 2 Hz
        self.timer = self.create_timer(0.5, self.tick)
        self.count = 0

        self.get_logger().info('Hello publisher started')

    def tick(self):
        msg = String()
        msg.data = f'hello from the rover, message {self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1


def main(args=None):
    rclpy.init(args=args)           # start up ROS
    node = HelloPublisher()
    try:
        rclpy.spin(node)            # hand control to ROS; run callbacks forever
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### Line by line

**`class HelloPublisher(Node)`** — your node inherits from `Node`, which gives you
`create_publisher`, `create_timer`, `get_logger` and the rest.

**`super().__init__('hello_publisher')`** — registers this name on the ROS graph.
It's what shows up in `ros2 node list`.

**`create_publisher(String, 'greeting', 10)`** — message type, topic name, and
**queue depth**. The queue holds messages if a subscriber is slow. 10 is a normal
default.

**`create_timer(0.5, self.tick)`** — ROS calls `self.tick` every 0.5 seconds.

> **Why a timer and not `while True:` with `sleep`?** A `while` loop blocks the
> node — it can't process incoming messages or respond to shutdown while sleeping.
> A timer hands control back to ROS between calls, so everything else keeps working.
> This is the single most common beginner mistake in ROS. Use timers.

**`rclpy.spin(node)`** — gives control to ROS. It sits there dispatching callbacks
until you `Ctrl+C`. Nothing after `spin` runs until the node shuts down.

**`self.get_logger().info(...)`** — ROS's `print`. It carries timestamps and node
names, and it works when your node is running on a rover instead of your laptop.
Use it, not `print()`.

## Registering the entry point

Writing the file isn't enough — ROS has to know it's runnable. Open `setup.py`:

```bash
nano ~/vanguard_ws/src/first_light/setup.py
```

Find `entry_points` and add a line:

```python
entry_points={
    'console_scripts': [
        'hello = first_light.hello:main',
    ],
},
```

The format is `command_name = package.module:function`:
- `hello` — what you'll type after `ros2 run first_light`
- `first_light.hello` — the package, then the file (no `.py`)
- `main` — the function to call

> **This is the step everyone forgets.** If `ros2 run` says
> *"No executable found"*, you either didn't add this line or didn't rebuild after.

## Build and run

```bash
cd ~/vanguard_ws
colcon build --symlink-install
source install/setup.bash
ros2 run first_light hello
```
```
[INFO] [1730294412.583] [hello_publisher]: Hello publisher started
[INFO] [1730294413.084] [hello_publisher]: Publishing: "hello from the rover, message 0"
[INFO] [1730294413.584] [hello_publisher]: Publishing: "hello from the rover, message 1"
```

In a second terminal, prove it's real:

```bash
ros2 topic echo /greeting
ros2 topic hz /greeting     # should read ~2.0
```

> ### What just happened
> You wrote a program that broadcasts on a named channel. It doesn't know or care
> whether anything is listening. Another program on another machine could subscribe
> and neither would need reconfiguring. That is the whole architecture.

## Now go and write yours

Your Sol 1 task needs a node that publishes **`geometry_msgs/msg/Twist`** to
**`/turtle1/cmd_vel`** at **10 Hz**, making the turtle draw a shape.

Things to work out for yourself:

1. **Different import.** `from geometry_msgs.msg import Twist` — not `String`.
2. **Different fields.** Run `ros2 interface show geometry_msgs/msg/Twist` and
   look. It's nested: `msg.linear.x`, `msg.angular.z`.
3. **10 Hz.** What timer period gives 10 Hz?
4. **A shape.** A circle is constant `linear.x` and constant `angular.z` — that's
   the easy one. A square needs you to *change* the velocities over time: drive,
   stop, turn, repeat. Squares are more interesting and score better.
5. **Name the entry point `circle`** so the automated checks can find it. Yes, even
   if you drew a square.

Check `ros2 topic hz /turtle1/cmd_vel` really shows ~10.

## If it went wrong

**`No executable found`**
`setup.py` entry point missing or misspelled, or you didn't rebuild. Do both.

**`ModuleNotFoundError: No module named 'first_light'`**
Didn't source `install/setup.bash` in this terminal.

**Node runs, turtle doesn't move**
Check the topic name. `ros2 topic info /turtle1/cmd_vel` — if `Publisher count`
is 0, your node is publishing somewhere else. A leading `/` matters:
`'turtle1/cmd_vel'` and `'/turtle1/cmd_vel'` resolve differently depending on
namespace. Use the leading slash.

**`AttributeError: 'Twist' object has no attribute 'x'`**
It's `msg.linear.x`, not `msg.x`. Look at `ros2 interface show` again.

**Turtle moves once and stops**
You published in `__init__` instead of from a timer callback. One message, one move.

**Turtle spirals off and hits the wall**
Expected — `turtlesim` has walls. Reset with `ros2 service call /reset std_srvs/srv/Empty`.

---

That's the handbook. Go back to [`sols/sol1/README.md`](../sols/sol1/README.md)
and finish the mission.
