# 03 — `.bashrc`, `PATH`, and why `source` exists

> **Time:** 30 minutes. Read this one properly.
> **By the end:** you'll understand the error that costs every ROS beginner an
> evening, and you'll never lose that evening.

Here is the single most common exchange in robotics:

> "`ros2: command not found`."
> "Did you source it?"
> "…what?"

This page is that answer. Everything below builds to it.

---

## Environment variables

Every running program has a set of named values attached to it — its **environment**.

```bash
echo $HOME
```
```
/home/krithin
```

`$` means *the value of*. Set one yourself:

```bash
MY_ROVER=perseverance
echo $MY_ROVER
```
```
perseverance
```

Now — and this is the important part — **open a new terminal and try again**:

```bash
echo $MY_ROVER
```
```

```

Empty. The variable belonged to that one terminal. It died with it.

> **Every terminal window is a separate world.** Things you set in one do not exist
> in another. Hold on to this; it explains almost everything that follows.

## `PATH`

```bash
echo $PATH
```
```
/usr/local/bin:/usr/bin:/bin:/usr/games
```

A colon-separated list of directories. When you type `ls`, the shell walks that
list looking for a program called `ls` and runs the first match.

**If a program isn't in a `PATH` directory, typing its name gives
`command not found`** — even if it's installed and sitting right there on disk.

That's the whole mystery. `ros2` is installed at `/opt/ros/jazzy/bin/ros2`, and
`/opt/ros/jazzy/bin` is not in your `PATH` by default.

## `source`

ROS ships a script that sets up your environment:

```bash
source /opt/ros/jazzy/setup.bash
```

It adds ROS to `PATH`, sets `ROS_DISTRO=jazzy`, and sets several other variables
ROS needs to find its own packages.

Check:

```bash
echo $ROS_DISTRO
which ros2
```
```
jazzy
/opt/ros/jazzy/bin/ros2
```

### Why `source` and not `./setup.bash`

This distinction is worth thirty seconds.

- **`./setup.bash`** runs the script in a *new* shell. It sets variables in that
  new shell, which then exits, taking them with it. **Nothing changes for you.**
- **`source setup.bash`** runs it in your *current* shell. The variables land in
  the terminal you're sitting in. **This is what you want.**

`.` is shorthand for `source`, so `. setup.bash` is the same thing. You'll see both.

> ### What just happened
> `source` didn't install anything. ROS was already on disk. It edited a few
> variables in this one terminal so the shell can now find what was always there.

## And then you open a new terminal

```bash
ros2 --version
```
```
bash: ros2: command not found
```

Of course. New terminal, new environment. The `source` you ran applied to the old one.

## `.bashrc` — the fix

`~/.bashrc` is a script that runs **automatically every time you open a terminal**.
Put the `source` line in there and every new terminal arrives ready.

```bash
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
```

> ⚠ **`>>` appends. `>` overwrites.** `>` would erase your entire `.bashrc`.
> One character. Get it right.

Apply it to the terminal you're in right now:

```bash
source ~/.bashrc
```

Or just open a new terminal. From here on, every terminal has ROS.

### Look at it

```bash
cat ~/.bashrc | tail -5
```

Or edit it:

```bash
nano ~/.bashrc
```

Nano's controls are along the bottom. `^O` means `Ctrl+O` (save), `^X` is exit.

## Diagnosing this yourself, forever

When a ROS command isn't found:

```bash
echo $ROS_DISTRO       # empty?      → not sourced
which ros2             # nothing?    → not on PATH
ls /opt/ros/jazzy      # missing?    → not installed at all
```

Three commands, in that order. They separate "not installed" from "not sourced" —
two completely different problems that produce an identical error message.

## Later: two things to source

Once you build your own packages you'll have a second setup file:

```bash
source /opt/ros/jazzy/setup.bash        # ROS itself
source ~/vanguard_ws/install/setup.bash # your own packages
```

Order matters — ROS first, yours second. Yours *overlays* ROS's. We'll come back
to this in [`06-workspace-and-packages.md`](06-workspace-and-packages.md).

---

## The one-line summary

**Installed ≠ available.** Installing puts files on disk. `source` tells *this
terminal* where they are. `.bashrc` does that automatically for every future terminal.

Next: [`04-install-ros2.md`](04-install-ros2.md).
