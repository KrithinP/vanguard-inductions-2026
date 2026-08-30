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

### 0. Star and Watch this repository

Two clicks, top right, and both are useful to you:

- ⭐ **Star** — tells us how many people are actually taking part, which is how we
  decide how much support to staff. Takes a second and genuinely helps.
- 👁 **Watch → All Activity** — you'll see any fixes or clarifications we push.

### 1. Fork this repository

**Fork**, top right. That gives you your own copy to work in.

### 2. Clone it

```bash
git clone https://github.com/YOUR-USERNAME/vanguard-inductions-2026.git
cd vanguard-inductions-2026
```

### 3. Let git talk to GitHub

**This will stop you the first time you try to push, so do it now.** GitHub
removed password authentication — typing your account password fails with
*"Support for password authentication was removed."*

Easiest fix, on any OS:

```bash
gh auth login
```

Choose **GitHub.com → HTTPS → Login with a web browser**, and paste the code it
shows you. Done once, works forever.

*(If `gh` isn't installed: `sudo apt install gh` on Ubuntu, `brew install gh` on
macOS, or download from [cli.github.com](https://cli.github.com). On Windows,
Git for Windows also offers a browser login the first time you push.)*

### 4. Tell git who you are

On a fresh machine git doesn't know, and won't let you commit until you say:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 5. Turn on Actions in your fork

Go to the **Actions** tab of *your fork* and click
**"I understand my workflows, go ahead and enable them."**

**GitHub disables workflows on new forks by default.** Until you click this, your
pushes are never checked and you get no feedback at all. One click, once.

### 6. Pick a callsign

Flight controllers go by callsign, not name. 3–16 characters, letters and numbers,
upper case. This is what appears on the progress board — **your real name doesn't.**

```bash
echo "NIGHTJAR" > callsign.txt
```

### 7. Get an environment

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

**All four missions are here from the start.** Nothing unlocks, nothing is
timed, and joining late costs you nothing.

| | Mission | |
|---|---|---|
| **1** | [Boot Sequence](sols/sol1/README.md) | setup, the terminal, ROS 2, your first node |
| **2** | [Rolling Chassis](sols/sol2/README.md) | build the rover and drive it |
| **3** | [Eyes](sols/sol3/README.md) | camera, markers, where things are in 3-D |
| **4** | [The World Model](sols/sol4/README.md) | ⭐ **bonus** — sensors, maps, navigation |

**Do them in order.** Each one builds directly on the last, and Mission 1 is the
one everything else stands on.

**You are not expected to finish all of them.** Mission 1 alone, understood
properly, is a perfectly good submission — and beats all four with code you can't
explain. Mission 4 is bonus: it can only add, never subtract.

**Printable guides live in [`tasks/`](tasks/).** We hand these out one at a time
over WhatsApp, and every one we've sent so far is in that folder — so if you joined
the group late, you haven't missed anything. Everything in them is also in
[`handbook/`](handbook/).

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
thing explained out loud.

**Where to put it:** upload to Google Drive (set *Anyone with the link → Viewer*)
or YouTube as **Unlisted**, and paste the link in your PR. **Check the link works
in a private/incognito window** — a Drive file nobody can open is the single most
common submission problem. Don't commit video files to git; the repo rejects them.

Record with whatever you have: OBS, the Xbox Game Bar (`Win+G`), QuickTime on
macOS, or your phone pointed at the screen. **Production quality is worth nothing
here** — we want to hear you explain one thing.

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
