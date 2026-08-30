<div align="center">

# 🛰 PROJECT VANGUARD
### Autonomous Subsystem — Induction 2026

**BITS Pilani Hyderabad · Mars Rover Team**

</div>

---

> **MISSION LOG — SOL 1, 06:14 LOCAL**
>
> The rover survived descent. Barely.
>
> Telemetry is intermittent, the flight computer took a hit on the way down, and
> the mission directory came back corrupted. Somewhere in that wreckage is the
> authentication phrase we need to bring the vehicle back online.
>
> We're 400 million kilometres from the nearest person who could fix this by hand.
> Round-trip radio is between four and twenty-four minutes, so there is no such
> thing as real-time control. Whatever this rover does next, it decides for itself.
>
> That's your job now. Wake it up.

---

## What this is

The induction for the **Autonomous Subsystem** of Project Vanguard — the software
that lets our Mars rover think for itself. We build the perception, localisation
and navigation that lets a machine cross terrain nobody has mapped, without
anyone driving it.

This induction runs over roughly four weeks. **Missions are released one at a
time.** You'll get the next one when the current one closes — same as a real
mission, where you fly what's in front of you and the next phase is planned while
you're still flying this one.

**You are not expected to already know any of this.** The handbook assumes you
have never opened a terminal. If you can follow instructions carefully and stay
curious when things break, you can do this.

## What you need

- A laptop with ~60 GB free.
- A **GitHub account**. ([Sign up](https://github.com/signup) — use your institute
  email, it gets you free Pro.)
- Roughly **6–8 hours a week**. It's a real commitment; we'd rather you knew now.

You do **not** need prior Linux, ROS, robotics or Python experience.

## Start here

### 1. Fork this repository

Click **Fork**, top right. That gives you your own copy to work in.

### 2. Clone it to your machine

```bash
git clone https://github.com/YOUR-USERNAME/vanguard-inductions-2026.git
cd vanguard-inductions-2026
```

(If `git` isn't installed yet, that's fine — [`handbook/00`](handbook/00-install-ubuntu.md)
gets you there first.)

### 3. Pick a callsign

Flight controllers go by callsign, not name. Pick yours — 3 to 16 characters,
letters and numbers, upper case. Make it something you'd be happy to see on a
scoreboard.

```bash
echo "NIGHTJAR" > callsign.txt
```

This is what appears on the public progress board. **Your real name stays off it.**

### 4. Read the mission

**→ [`sols/`](sols/README.md) — your current mission**

The handbook in [`handbook/`](handbook/) walks you through everything the mission
needs, from installing Ubuntu to writing your first ROS 2 node. Read it in order.

## Submitting

1. Work on your fork, committing as you go. **Small, frequent commits with real
   messages** — `add velocity publisher`, not `stuff`. We look at this.
2. When you're done, open a **Pull Request** to this repository's `main`.
3. **PR title:** `NAME [ID_NUMBER]` — e.g. `Ada Lovelace [2026A7PS0042H]`
4. Fill in the template.
5. One PR per person. Keep pushing to it as the induction proceeds — the same PR
   carries all your work.

Every push runs an automatic **flight readiness poll** and reports GO / NO-GO on
each part of the mission. It's there so you can fix things before a human ever
looks. Check the Actions tab on your fork.

Run the same checks locally any time:

```bash
./tools/vanguard doctor    # is my machine set up correctly?
./tools/vanguard check     # is the current mission complete?
```

## How you'll be judged

Not on completion. Roughly, in order:

- **Understanding** — can you explain why your code works? Shortlisted recruits
  get a short walkthrough where we ask you to modify it live.
- **Correctness** — does it do the thing?
- **Engineering** — readable code, honest commits.
- **Honesty** — a clear account of what broke is worth more than pretending it didn't.

**Getting stuck is not failure. Hiding it is.** Every one of us has lost a weekend
to a missing `source` line.

## Using AI

You **may** use Claude, ChatGPT, Copilot — we're an AI-leveraged team and pretending
otherwise would be silly.

One rule: **you must understand every line you submit.** In the walkthrough we'll
ask you to explain your code and change it in front of us. If you can't, it doesn't
count, no matter how well it runs. Use AI to learn faster, not to think less.

## Asking for help

Questions go in **[Issues](../../issues/new/choose)**, not DMs. Public, searchable,
answered once — and someone after you will hit the same wall.

**Asking a good question is a skill we are explicitly looking for.** Include what
you tried, the exact command, the full error, and your `vanguard doctor` output.

---

<div align="center">

*Dare mighty things.*

</div>
