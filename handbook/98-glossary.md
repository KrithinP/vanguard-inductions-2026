# 98 — Glossary

Terms in the order you'll meet them.

**Terminal / shell** — the text window where you type commands. The shell is the
program interpreting them (ours is `bash`).

**Prompt** — `user@machine:~$`. Where the shell waits for input.

**Path** — a file's address. *Absolute* starts with `/`; *relative* doesn't.

**`~`** — your home directory, `/home/yourname`.

**Hidden file** — any name starting with `.`. Only shown by `ls -a`.

**`sudo`** — run one command as administrator.

**Package (apt)** — a unit of installable software.

**Repository** — a server holding packages.

**Environment variable** — a named value attached to a running shell. `$HOME`, `$PATH`.

**`PATH`** — the list of directories the shell searches for programs.

**`source`** — run a script *in the current shell* so its variables stick.

**`.bashrc`** — script that runs automatically in every new terminal.

**ROS 2** — the framework. Not an operating system, despite the name — a set of
libraries and tools for making robot programs talk to each other.

**Jazzy Jalisco** — the ROS 2 release we use. Pairs with Ubuntu 24.04.

**Node** — one running program in a ROS system.

**Topic** — a named channel that nodes publish to and subscribe from.

**Message** — one piece of data on a topic, with a defined type.

**Publisher / Subscriber** — a node sending / receiving on a topic.

**`Twist`** — the message type for velocity: linear and angular, 3 axes each.

**Queue depth** — how many messages to buffer for a slow subscriber.

**Timer / callback** — a function ROS calls on a schedule.

**`spin`** — hand control to ROS so it can dispatch callbacks.

**Workspace** — a directory where you build your own ROS packages.

**`src/` `build/` `install/` `log/`** — you write in `src/`; the rest is generated.

**Package (ROS)** — one unit of ROS code, with a name and declared dependencies.

**`colcon`** — the build tool.

**Entry point** — the line in `setup.py` that makes a Python file runnable via
`ros2 run`.

**`rclpy`** — the ROS 2 Python client library.

**Overlay** — sourcing your workspace on top of ROS, so your packages take priority.

**REP-103 / REP-105** — the conventions: metres, radians, x-forward, y-left, z-up.
