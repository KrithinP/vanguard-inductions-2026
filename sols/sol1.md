# SOL 1 — "Boot Sequence"

```
╔════════════════════════════════════════════════════════════════╗
║  SOL 001 · LANDING + 0                                         ║
║  SPROSCAPE · 18.4°N 77.5°E                                     ║
║  STATUS: SYSTEMS OFFLINE                                       ║
╠════════════════════════════════════════════════════════════════╣
║  Recover the workstation. Wake the flight computer.            ║
╚════════════════════════════════════════════════════════════════╝
```

> **Objective:** bring a workstation online, recover the mission authentication
> phrase, and put the rover's first command on the wire.
> **Effort:** 6–8 hours. Spread it over days — do not start this the night before.

---

## Mission briefing

A rover is not one program. It's dozens, running at once, talking to each other
over a network — one for the camera, one for the wheels, one deciding where to go.
Before you can write any of them, you need the environment they live in, and you
need to be able to *see* what they're saying to each other.

That's Sol 1. It's the least glamorous mission you'll fly and the one everything
else stands on.

You'll also find the mission directory came back from descent corrupted. Recovering
it is how you'll learn the terminal — not by reading a list of commands, but by
needing them.

---

## Tasks

### 1 · Get the workstation running

Install **Ubuntu 24.04 LTS**.

 [`handbook/00-install-ubuntu.md`](../handbook/00-install-ubuntu.md)

Confirm with `lsb_release -a` — it must say `Release: 24.04`.

### 2 · Learn to drive the terminal

 [`handbook/01-terminal.md`](../handbook/01-terminal.md)

Read it with a terminal open. Type every command as you go. Reading about `grep`
teaches you nothing; using it teaches you `grep`.

### 3 · Understand `apt`

 [`handbook/02-apt.md`](../handbook/02-apt.md)

### 4 · Understand `.bashrc`, `PATH` and `source`

 [`handbook/03-bashrc-path-source.md`](../handbook/03-bashrc-path-source.md)

**Do not skim this one.** It is the difference between debugging your code and
debugging your shell, and almost everyone who skips it loses an evening to
`command not found` within the week.

### 5 · Install ROS 2 Jazzy

 [`handbook/04-install-ros2.md`](../handbook/04-install-ros2.md)

Finish with:

```bash
./tools/vanguard doctor
```

Every line must read **GO** before you continue.

### 6 · Learn to inspect a running system

 [`handbook/05-nodes-and-topics.md`](../handbook/05-nodes-and-topics.md)

Run turtlesim and work through the nine inspection commands. Drive the turtle by
hand with `ros2 topic pub` before you write any code.

### 7 · Recover the mission directory

Somewhere in this repository is a hidden directory holding three fragments of the
authentication phrase. Find them.

You'll need: listing hidden files, searching recursively inside files, making a
script executable, and extracting an archive. All four are in
[`handbook/01`](../handbook/01-terminal.md).

> **Start with:** `ls -a`
>
> Everything else follows from noticing what's there.

### 8 · Authenticate

Join the three fragments with hyphens, in order, upper case. Then hash them with
your callsign:

```bash
echo -n "FRAGMENT1-FRAGMENT2-FRAGMENT3:YOURCALLSIGN" | sha256sum | cut -c1-16
```

Write those 16 characters into `FLAG.txt` at the repo root:

```bash
echo "your16charresult" > FLAG.txt
```

Your callsign must match `callsign.txt` exactly. **The flag is derived from your
own callsign — copying someone else's will fail, and we will see that it failed.**

Need the reminder later: `./tools/vanguard flag`

### 9 · Write your first node

 [`handbook/06-workspace-and-packages.md`](../handbook/06-workspace-and-packages.md)
 [`handbook/07-first-node.md`](../handbook/07-first-node.md)

Build a package called **`first_light`** containing a node that:

- publishes **`geometry_msgs/msg/Twist`**
- to **`/turtle1/cmd_vel`**
- at **10 Hz**
- making the turtle draw a **shape** — a circle works; a square is better

Register the entry point as **`circle`** (even if you drew a square — the automated
checks look for that name):

```bash
ros2 run first_light circle
```

Then copy the package into this repository:

```bash
mkdir -p src/sol1
cp -r ~/vanguard_ws/src/first_light src/sol1/
```

> Copy the **source only**. Never commit `build/`, `install/` or `log/` —
> `.gitignore` already blocks them.

### 10 · Write your mission log

Create `MISSION_LOG.md` at the repo root. A few honest paragraphs:

- What did you get working?
- **What broke, and how did you work it out?**
- What still doesn't make sense to you?
- Roughly how long did it take?

The second and third questions are the ones we actually read. "I spent two hours on
`command not found` before realising I hadn't sourced" is a *good* entry — it tells
us you can diagnose. Nobody believes a log that says everything went fine.

---

## Checklist

Run this before you submit:

```bash
./tools/vanguard check
```

```
MISSION 1 — BOOT SEQUENCE
  GO    callsign = NIGHTJAR
  GO    flag submitted (verified at mission control)
  GO    package present at src/sol1/first_light
  GO    node source present
  GO    mission log written
  GO    colcon build succeeded
  GO    node publishes on /turtle1/cmd_vel

MISSION 2 — ROLLING CHASSIS
  ·     not started

MISSION 3 — EYES
  ·     not started

MISSION 4 — THE WORLD MODEL  (bonus)
  ·     not attempted — this costs you nothing

────────────────────────────────────────
Started: 1   Complete: 1
ALL STATIONS GO.
```

Missions you haven't started are ignored — they can never fail your build. The same
check runs automatically on every push to your fork.

| File | What it should be |
|---|---|
| `callsign.txt` | your callsign, upper case |
| `FLAG.txt` | 16 hex characters |
| `src/sol1/first_light/` | your package (source only) |
| `MISSION_LOG.md` | honest write-up |

## Submitting

Commit as you go, then open a Pull Request to this repository's `main`, titled
`NAME [ID_NUMBER]`.

**Also record a short screen capture** — under 90 seconds — showing your turtle
drawing its shape, with `ros2 topic hz /turtle1/cmd_vel` visible in a second
terminal. Link it in your PR. Don't commit the video file.

In that recording, **say out loud in one sentence why your node uses a timer
instead of a `while` loop.** We'd rather hear you explain one thing than watch a
polished demo.

---

## Stuck?

1. `./tools/vanguard doctor`
2. [`handbook/99-troubleshooting.md`](../handbook/99-troubleshooting.md)
3. [Open an Issue](../../issues/new/choose)

There is no penalty for asking. There's a real one for going quiet for a week.

---

<div align="center">

*One command. Four hundred million kilometres. Make it count.*

</div>
