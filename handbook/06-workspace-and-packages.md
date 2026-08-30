# 06 — Workspaces and packages

> **Time:** 30 minutes.
> **By the end:** you have your own ROS 2 package, built, and visible to `ros2 run`.

## Workspaces

A **workspace** is a directory where you build your own ROS code. It has one rule:
your source goes in `src/`, and the build tool creates everything else.

```bash
mkdir -p ~/vanguard_ws/src
cd ~/vanguard_ws
```

`-p` creates parent directories as needed. After building you'll have:

```
vanguard_ws/
├── src/       ← your code. The only directory you write in.
├── build/     ← intermediate build files    (generated)
├── install/   ← the finished, runnable result (generated)
└── log/       ← build logs                  (generated)
```

> **Never commit `build/`, `install/` or `log/` to git.** They're generated,
> enormous, and machine-specific. Our `.gitignore` already excludes them —
> if you ever see them in `git status`, something is wrong.

## Packages

A **package** is one unit of ROS code — it has a name, declares its dependencies,
and can be built and run. Everything in ROS is a package, including everything you
installed with apt.

Create one:

```bash
cd ~/vanguard_ws/src
ros2 pkg create first_light \
  --build-type ament_python \
  --dependencies rclpy geometry_msgs \
  --license Apache-2.0
```

Breaking that down:
- `first_light` — the package name. Lower case, underscores, no hyphens. ROS is
  strict about this and the error when you get it wrong is not obvious.
- `--build-type ament_python` — a Python package. (C++ would be `ament_cmake`.)
- `--dependencies rclpy geometry_msgs` — `rclpy` is the ROS 2 Python library;
  `geometry_msgs` has `Twist`. Declaring them here writes them into `package.xml`.
- `--license Apache-2.0` — optional, but omitting it prints a long warning.

> **Warning —** Put the package name first.** `--dependencies` accepts any number of values,
> so if you write it before the name, it swallows the name as a dependency and you
> get `error: the following arguments are required: package_name`. Either put the
> name first as above, or put `--dependencies` last.

You get:

```
first_light/
├── first_light/          ← your Python code goes HERE
│   └── __init__.py
├── resource/first_light
├── test/
├── package.xml           ← name, version, dependencies
├── setup.py              ← how to build and install it
└── setup.cfg
```

> **Yes, `first_light/first_light/`.** The outer is the package directory; the
> inner is the Python module. Everyone finds this odd. Your code goes in the inner one.

## Building

Always build from the **workspace root**, never from inside a package:

```bash
cd ~/vanguard_ws
colcon build
```
```
Starting >>> first_light
Finished <<< first_light [0.94s]

Summary: 1 package finished [1.31s]
```

Useful variations:

```bash
colcon build --symlink-install          # edit Python without rebuilding
colcon build --packages-select first_light   # build just one package
```

`--symlink-install` links to your source instead of copying it, so editing a Python
file takes effect immediately. **Use it — it'll save you a hundred rebuilds.**

## Sourcing your workspace

Building doesn't make ROS aware of your package. You have to source it:

```bash
source ~/vanguard_ws/install/setup.bash
```

Now `ros2 run first_light ...` works. Same lesson as
[`03`](03-bashrc-path-source.md): building put files on disk, sourcing told this
terminal where they are.

Make it automatic:

```bash
echo "source ~/vanguard_ws/install/setup.bash" >> ~/.bashrc
```

Your `~/.bashrc` should now end with **two** source lines, in this order:

```bash
source /opt/ros/jazzy/setup.bash
source ~/vanguard_ws/install/setup.bash
```

ROS first, yours second — yours *overlays* ROS's, so your packages can override
system ones.

> **Warning —** Chicken and egg.** If `install/setup.bash` doesn't exist yet, that second
> line prints an error in every new terminal. Build once first, or ignore the
> complaint until you have.

## The rebuild ritual

You will do this hundreds of times. Learn it now:

```bash
cd ~/vanguard_ws
colcon build --symlink-install
source install/setup.bash
ros2 run first_light <node>
```

When something you *know* you fixed still misbehaves, 90% of the time you either
didn't rebuild or didn't re-source. Check that before you debug anything else.

## If it went wrong

**`colcon: command not found`**
```bash
sudo apt install -y python3-colcon-common-extensions
```

**`Package 'first_light' not found`**
Not sourced, or the build failed. Run `colcon build` again and read the output —
`Finished` means good, `Failed` means read the error above it.

**Build succeeds but `ros2 run` says no executable**
Your entry point isn't registered in `setup.py`. That's the next page.

**Build says `Finished` but `ros2 run` says `Package 'first_light' not found`**
Look near the top of the build output for:
```
WARNING: Failed to parse ROS package manifest ... Invalid email "..." for person
```
`ros2 pkg create` copies your **git email** into `package.xml` as the maintainer.
If that address is malformed, colcon *warns*, reports success anyway, and quietly
builds something ROS can never find. Open `package.xml`, fix the
`<maintainer email="...">` line to a real address, and rebuild. Then fix it at
source so it doesn't recur:
```bash
git config --global user.email "your.real@email.com"
```
`./tools/vanguard doctor` now checks this for you.

**Weird errors after renaming or moving things**
Stale build artefacts. Nuke and rebuild:
```bash
cd ~/vanguard_ws && rm -rf build install log && colcon build --symlink-install
```

**`SetuptoolsDeprecationWarning`**
Noise, not an error. Ignore it.

Next: [`07-first-node.md`](07-first-node.md) — where you finally write something.
