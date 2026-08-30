# 99 — Troubleshooting index

Every error in this handbook, in one place. `Ctrl+F` for your error text.

## Before anything else

```bash
./tools/vanguard doctor
```

It checks the whole environment and prints the fix for each failure. Run it first,
every time. When you open an Issue, paste its output.

## The three-command diagnosis

When a ROS command isn't found, run these in order:

```bash
echo $ROS_DISTRO       # empty     → not sourced
which ros2             # nothing   → not on PATH
ls /opt/ros/jazzy      # missing   → not installed
```

They separate "not installed" from "not sourced" — two different problems with the
same error message.

## Errors

| Error | Cause | Fix |
|---|---|---|
| `Support for password authentication was removed` | GitHub killed password auth | `gh auth login` → HTTPS → browser · [README](../README.md) |
| `bad interpreter: /bin/bash^M` | Windows line endings (CRLF) | `git config --global core.autocrlf input`, then re-clone |
| Actions tab says workflows are disabled | GitHub disables them on new forks | Click *"I understand my workflows…"* on **your fork's** Actions tab |
| `Permission denied (publickey)` on push | No SSH key, or wrong remote | Easiest: `gh auth login` and use HTTPS |
| Docker Desktop won't start (Windows) | Virtualization off in BIOS, or WSL 2 missing | Enable *Intel VT-x / AMD-V* in BIOS; `wsl --install` in PowerShell |
| `no space left on device` mid-build | Docker images are large | `docker system prune -a` frees old layers |
| `ros2: command not found` | Not sourced | `source /opt/ros/jazzy/setup.bash` · [03](03-bashrc-path-source.md) |
| `Unable to locate package ros-jazzy-*` | Repo not added, or no `apt update` | [04 step 3](04-install-ros2.md) |
| `curl: (35) Connection reset` on the ROS key | Flaky network to GitHub | **Just retry** — often works on the 3rd or 4th go · [04](04-install-ros2.md) |
| `Author identity unknown` / can't commit | git doesn't know who you are | `git config --global user.name "..."` and `user.email` |
| `GPG error` / `NO_PUBKEY` | Signing key missing | Redo the `curl` in [04 step 3](04-install-ros2.md) |
| `Could not get lock /var/lib/dpkg/` | Another apt is running | Wait, then [02](02-apt.md) |
| `externally-managed-environment` | Ubuntu 24.04 pip policy | Add `--user --break-system-packages` |
| `colcon: command not found` | Not installed | `sudo apt install python3-colcon-common-extensions` |
| `ros2 pkg create: error: ... required: package_name` | `--dependencies` swallowed the name | Put the package name first · [06](06-workspace-and-packages.md) |
| `Package 'x' not found` | Not built or not sourced | `colcon build` then `source install/setup.bash` |
| Build says success but `Package 'x' not found` | Invalid maintainer email in `package.xml` | colcon only *warns*. Fix the email in `package.xml` · [06](06-workspace-and-packages.md) |
| `No executable found` | Missing `setup.py` entry point | [07](07-first-node.md) |
| `ModuleNotFoundError: No module named` | Workspace not sourced | `source ~/vanguard_ws/install/setup.bash` |
| `AttributeError: 'Twist' has no attribute 'x'` | It's nested | `msg.linear.x` · [07](07-first-node.md) |
| `Permission denied` running a script | No execute bit | `chmod +x script.sh` · [01](01-terminal.md) |
| Talker/listener can't hear each other | Another ROS on the network | `export ROS_DOMAIN_ID=42` in both |
| Node runs, robot doesn't move | Wrong topic | `ros2 topic info <topic>` — check `Publisher count` |
| Turtle moves once and stops | Published in `__init__`, not a timer | [07](07-first-node.md) |
| Fixed it but nothing changed | Didn't rebuild or re-source | `colcon build && source install/setup.bash` |
| Strange errors after renaming files | Stale build artefacts | `rm -rf build install log && colcon build` |
| No boot menu after installing Ubuntu | Secure Boot / Fast Startup | [00](00-install-ubuntu.md) |
| Wi-Fi dead in Ubuntu | Broadcom driver | `sudo apt install bcmwl-kernel-source` |
| Out of disk during install | Partition too small | `sudo apt clean && sudo apt autoremove` |

## The nuclear option

When a workspace is behaving impossibly:

```bash
cd ~/vanguard_ws
rm -rf build install log
colcon build --symlink-install
source install/setup.bash
```

This is safe — those three directories are all generated. It fixes a surprising
number of problems.

## Still stuck

[Open an Issue.](../../../issues/new/choose) Include:

1. What you were trying to do
2. The **exact** command you ran
3. The **full** error, not a summary
4. Output of `./tools/vanguard doctor`
5. What you already tried

Questions go in Issues, not DMs — so everyone benefits from the answer, and so we
answer it once. **How well you ask is something we're evaluating.** A good question
is a strong signal; "it doesn't work" is also a signal.
