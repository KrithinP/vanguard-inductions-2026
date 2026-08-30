# 🛰 PROJECT VANGUARD — Autonomous Subsystem Induction 2026

**BITS Pilani Hyderabad · Mars Rover Team**

---

> On Mars, a radio message takes between four and twenty-four minutes to make the
> round trip. Real-time driving is impossible. Every move the rover makes, it
> decides for itself.
>
> That software is what this subsystem builds. This induction is how you learn to
> write it.

---

## Contents

1. [What you need](#what-you-need)
2. [Set up](#set-up)
3. [Your missions](#your-missions)
4. [Submitting](#submitting)
5. [How you'll be judged](#how-youll-be-judged)
6. [Using AI](#using-ai)
7. [Asking for help](#asking-for-help)

---

## What you need

- A laptop with **8 GB RAM** and ~20 GB free (60 GB to install Ubuntu directly).
- A **GitHub account** — [sign up](https://github.com/signup) with your institute
  email for free Pro.
- About **6–8 hours a week**. It's a real commitment.

**No prior Linux, ROS, robotics or Python experience is assumed.** The handbook
starts from "what is a terminal".

## Set up

### 1. Fork this repository

**Fork**, top right. That gives you your own copy to work in.

### 2. Clone it

```bash
git clone https://github.com/YOUR-USERNAME/vanguard-inductions-2026.git
cd vanguard-inductions-2026
```

### 3. Tell git who you are

On a fresh machine git doesn't know, and won't let you commit until you say:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Pick a callsign

Flight controllers go by callsign, not name. 3–16 characters, letters and numbers,
upper case. This is what appears on the progress board — **your real name doesn't.**

```bash
echo "NIGHTJAR" > callsign.txt
```

### 5. Get an environment

Two routes, **both fully supported**:

| | For | Start at |
|---|---|---|
| 🐳 **Docker** | Windows 10/11, macOS (incl. Apple Silicon), any Linux. No dual boot, nothing touches your partitions. | [`docker/README.md`](docker/README.md) |
| 🐧 **Ubuntu 24.04** | Dual boot or a spare machine. Faster, and what the team runs. | [`handbook/00`](handbook/00-install-ubuntu.md) |

On Windows or a Mac and unsure? **Use Docker.**

Check yourself at any point:

```bash
./tools/vanguard doctor    # is my machine set up correctly?
./tools/vanguard check     # is the current mission complete?
```

## Your missions

**→ [`sols/`](sols/README.md)**

Missions are released one at a time through the induction — you'll get the next
when the current one closes, the same way a real mission flies what's in front of
it while the next phase is still being planned.

Each mission tells you which parts of [`handbook/`](handbook/) you need.

## Submitting

1. Work on your fork, committing as you go. **Small, frequent commits with real
   messages** — `add velocity publisher`, not `stuff`. We read these.
2. Open **one Pull Request** to this repository's `main`, titled
   `NAME [ID_NUMBER]` — e.g. `Ada Lovelace [2026A7PS0042H]`.
3. Keep pushing to that same PR as the induction goes on. One PR carries all your
   work.

Every push runs an automatic **flight readiness poll** that reports GO / NO-GO on
each part of the current mission — so you can fix things before a human looks.
It's in the Actions tab of your fork.

Each mission also asks for a **short screen recording, under 90 seconds**, with one
thing explained out loud. Link it in your PR; don't commit video files.

| | |
|---|---|
| **Induction opens** | 30 August 2026 |
| **Everything due** | **23 September 2026, 23:59 IST** |

## How you'll be judged

Not on how much you finish. Roughly, in order:

- **Understanding** — can you explain why your code works? Shortlisted recruits get
  a short walkthrough where we ask you to modify it live.
- **Correctness** — does it do the thing?
- **Engineering** — readable code, honest commits.
- **Honesty** — a clear account of what broke is worth more than pretending it didn't.

**Finishing only the first mission, and understanding it, beats finishing them all
with code you can't explain.**

Getting stuck is not failure. Hiding it is. Every one of us has lost a weekend to a
missing `source` line.

## Using AI

You **may** use Claude, ChatGPT, Copilot — we're an AI-leveraged team and
pretending otherwise would be silly.

One rule: **you must understand every line you submit.** In the walkthrough we'll
ask you to explain your code and change it in front of us. If you can't, it doesn't
count, however well it runs. Use AI to learn faster, not to think less.

## Asking for help

Questions go in **[Issues](../../issues/new/choose)**, not DMs. Public, searchable,
answered once — and someone after you will hit the same wall.

**Asking a good question is a skill we're explicitly looking for.** Include what
you tried, the exact command, the full error, and your `vanguard doctor` output.

**Evaluator:** Krithin Poola — Autonomous Lead, Project Vanguard.

---

## One more thing

Somewhere in this repository is something we haven't mentioned anywhere. It isn't
part of any mission and nothing tells you where to look. Find it, open an Issue
saying what it says, and there are **brownie points** in it for you.

Perseverance's parachute had *Dare Mighty Things* woven into it in binary, and
Curiosity's wheels stamp "JPL" in Morse into the dirt of Mars with every turn.
Engineers hide things. Go and be curious.

---

*Dare mighty things.*
