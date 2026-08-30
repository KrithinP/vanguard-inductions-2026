# 04 — Installing ROS 2 Jazzy

> **Time:** 30–60 minutes, mostly downloading (~3 GB).
> **Prerequisite:** Ubuntu 24.04 confirmed via `lsb_release -a`.

**Jazzy Jalisco** is the ROS 2 release that pairs with Ubuntu 24.04. Every ROS 2
release supports exactly one Ubuntu LTS — that's why the version matching in
[`00`](00-install-ubuntu.md) was not optional.

Run these in order. Don't skip ahead; each depends on the last.

## 1. Locale

ROS needs a UTF-8 locale.

```bash
locale  # check current
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

## 2. Enable the universe repository

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository universe
```

Press Enter if it asks to confirm.

## 3. Add the ROS 2 repository

The signing key first:

```bash
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg
```

> **Warning —** If that `curl` fails, run it again.** `raw.githubusercontent.com` is
> intermittently unreachable from some campus and mobile networks — we saw it fail
> three times in a row and then succeed on the fourth. Errors that mean "try
> again", not "you did it wrong":
> ```
> curl: (35) OpenSSL SSL_connect: Connection reset by peer
> curl: (28) Operation timed out
> ```
> Check you actually got the key before moving on — an empty file causes a very
> confusing `NO_PUBKEY` error two steps later:
> ```bash
> ls -la /usr/share/keyrings/ros-archive-keyring.gpg
> ```
> It should be about **1.2 kB**. If it's 0 bytes, the download failed. Still stuck
> after several tries? Use a phone hotspot for this one command, or
> [open an Issue](../../../issues/new/choose).

Then the repository itself:

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
  | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
```

That's one long line — copy all of it. `$(...)` runs a command and drops its output
in place, so this fills in your architecture (`amd64`) and Ubuntu codename (`noble`)
automatically. Check it landed correctly:

```bash
cat /etc/apt/sources.list.d/ros2.list
```
```
deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu noble main
```

**It must say `noble`.** If it says anything else, you are not on Ubuntu 24.04.

## 4. Install

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-jazzy-desktop
```

That last one is the big download. Go and make coffee.

`ros-jazzy-desktop` gives you ROS 2 plus RViz, demos and tutorials. (There's a
smaller `ros-jazzy-ros-base` without GUI tools — you don't want it, you need RViz.)

## 5. The rest of the team toolchain

These are the packages the team standardises on. Installing them now means the
rest of the induction just works.

```bash
sudo apt install -y \
  python3-colcon-common-extensions \
  python3-rosdep \
  python3-pip \
  ros-jazzy-ros-gz \
  ros-jazzy-turtlesim \
  ros-jazzy-rqt-graph \
  ros-jazzy-tf2-tools \
  ros-jazzy-teleop-twist-keyboard

pip install --user --break-system-packages opencv-contrib-python
pip install --user --break-system-packages "numpy<2"
```

> **Warning —** Both lines, in that order.** ROS 2's `cv_bridge` is compiled against
> NumPy 1.x. Installing OpenCV pulls in NumPy 2.x, which breaks `cv_bridge` at
> runtime with a long `ImportError` about *"a module compiled using NumPy 1.x
> cannot be run in NumPy 2.x"*. The second line puts NumPy back where ROS expects
> it. Check with:
>
> ```bash
> python3 -c "import numpy; print(numpy.__version__)"   # must start with 1.
> ```

Initialise `rosdep` (resolves dependencies when you build):

```bash
sudo rosdep init
rosdep update
```

> `sudo rosdep init` saying *"already exists"* is fine. Move on.

> **Why `opencv-contrib-python` and not `opencv-python`?** The contrib build
> includes extra modules the plain one omits. Installing plain `opencv-python`
> later will silently shadow this and break things in a confusing way. Don't.

## 6. Tell git who you are

If you haven't already (the README asks for this too):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

`./tools/vanguard doctor` checks for these, because git refuses to commit without
them and the error it gives is not obvious.

## 7. Source it

```bash
source /opt/ros/jazzy/setup.bash
```

Make it permanent:

```bash
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

If that line meant nothing to you, go back and read
[`03-bashrc-path-source.md`](03-bashrc-path-source.md). You'll need it within the hour.

## 8. Verify

```bash
ros2 --version
```
```
ros2 cli version: 0.32.x
```

```bash
echo $ROS_DISTRO
```
```
jazzy
```

Now the real test — two terminals.

**Terminal 1:**
```bash
ros2 run demo_nodes_cpp talker
```
```
[INFO] [talker]: Publishing: 'Hello World: 1'
[INFO] [talker]: Publishing: 'Hello World: 2'
```

**Terminal 2:**
```bash
ros2 run demo_nodes_py listener
```
```
[INFO] [listener]: I heard: [Hello World: 3]
[INFO] [listener]: I heard: [Hello World: 4]
```

`Ctrl+C` to stop each.

> ### What just happened
> Two separate programs, started independently, with no configuration, found each
> other and started talking. Neither knows the other's name or location. That
> discovery mechanism is the core of ROS 2 — and it's how nodes on a laptop find
> nodes on a rover over Wi-Fi with nothing more than being on the same network.

## 9. Run the doctor

From the induction repo:

```bash
./tools/vanguard doctor
```

Every line should read **GO**. Fix any **NO-GO** before continuing — each one
prints the command that fixes it.

---

## If it went wrong

**`Unable to locate package ros-jazzy-desktop`**
Step 3 didn't work. Check `cat /etc/apt/sources.list.d/ros2.list` says `noble`,
then `sudo apt update` again and read the output for errors.

**`GPG error` / `NO_PUBKEY`**
The key didn't install. Re-run the `curl` command in step 3, then
`sudo apt update`.

**`ros2: command not found` after installing**
Not sourced. `source /opt/ros/jazzy/setup.bash`, then read
[`03`](03-bashrc-path-source.md).

**talker and listener don't hear each other**
Usually another ROS on the network — you're hearing someone else's, or they're
hearing yours. Isolate yourself:
```bash
export ROS_DOMAIN_ID=42     # pick any number 0-101
```
Set it in both terminals. Add it to `~/.bashrc` if it helps.

**`error: externally-managed-environment` from pip**
Expected on 24.04. Add `--user --break-system-packages`, as shown in step 5.

**Ran out of disk space mid-install**
```bash
sudo apt clean && sudo apt autoremove
df -h            # check free space
```
ROS needs ~4 GB. If you're tight, you undersized your Ubuntu partition.

Next: [`05-nodes-and-topics.md`](05-nodes-and-topics.md).
