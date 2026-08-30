<div align="center">

# PROJECT VANGUARD
### Autonomous Subsystem — Induction 2026

**BITS Pilani Hyderabad · Mars Rover Team**

![ROS 2](https://img.shields.io/badge/ROS_2-Jazzy-22314E?logo=ros&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420?logo=ubuntu&logoColor=white)
![Gazebo](https://img.shields.io/badge/Gazebo-Harmonic-F58113?logo=gazebo&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)
[![Flight Readiness Poll](https://github.com/KrithinP/vanguard-inductions-2026/actions/workflows/checks.yml/badge.svg)](https://github.com/KrithinP/vanguard-inductions-2026/actions/workflows/checks.yml)

</div>

---

> On Mars, a radio message takes four to twenty-four minutes to make the round
> trip. Real-time driving is impossible. Every move the rover makes, it decides
> for itself.
>
> That software is what this subsystem builds.

---

---

Everything you need is in this repository: the four tasks, a reference handbook
that starts from *what is a terminal*, a zero-install environment, and tooling
that checks your work before a human ever sees it.

> ### Why we count in Sols
>
> A Martian solar day is **24 hours, 39 minutes and 35 seconds**. It's called a
> **sol**, and it's just long enough to be a genuine nuisance: mission teams
> working surface operations live on Mars time, so their working day slides about
> forty minutes later than everyone else's, every single day. After a fortnight
> you're eating breakfast at midnight.
>
> Rovers count their lives in sols. Opportunity was built for 90 and lasted 5,111.
> So do we.

## The Sols

These are the tasks. Do them in order.

- **Sol 1** — [sols/sol1.md](sols/sol1.md) · separate sheets for Windows, macOS and Linux
- **Sol 2** — [sols/sol2.md](sols/sol2.md)
- **Sol 3** — [sols/sol3.md](sols/sol3.md)
- **Sol 4** — [sols/sol4.md](sols/sol4.md) · **bonus**

**Sols 1–3 are compulsory. Sol 4 is a bonus** — it can only add to your
evaluation, never subtract, and finishing it earns serious brownie points.

Each `.md` above is the **brief** — what to build and what to hand in — and links
to the [`handbook/`](handbook/) chapters you need. The **PDFs in
[`sols/`](sols/README.md) contain the entire task in one file**: the brief plus
every handbook chapter it depends on, bundled inline. Use whichever suits you.

> ### It looks like a lot. It isn't as bad as it looks.
>
> **Everything is written out step by step.** Every command is shown with the
> output you should see, every concept is explained before it's used, and every
> error we know about has an entry in
> [`handbook/99-troubleshooting.md`](handbook/99-troubleshooting.md) with the fix.
>
> **Most of the early effort goes into the environment, not the code.** That is
> why so much has been written about it.
>
> **The support thins out as you go, on purpose.** Sol 1 hands you a working
> example. By Sol 4 you get the problem described and build it yourself. If Sol 4
> feels hard, that is the design.

## What you need

- A laptop with **8 GB RAM** and ~20 GB free (60 GB to install Ubuntu directly).
- A **GitHub account** — [sign up](https://github.com/signup) with your institute
  email for free Pro.
- About **6–8 hours a week**.

**No prior Linux, ROS, robotics or Python experience is assumed.** The handbook
starts from "what is a terminal".

## Getting set up

### 1. Star this repository

 top right. It's how we gauge how many people are taking part, which decides how
much support we staff.

### 2. Fork it, then clone your fork

```bash
git clone https://github.com/YOUR-USERNAME/vanguard-inductions-2026.git
cd vanguard-inductions-2026
```

### 3. Let git talk to GitHub

```bash
gh auth login
```

Choose **GitHub.com → HTTPS → Login with a web browser**. GitHub removed password
authentication, so without this your first `git push` fails.

### 4. Tell git who you are

```bash
git config --global user.name "Your Name"
git config --global user.email "your.real@email.com"
```

Use a **real, well-formed address**. ROS copies it into package metadata, and a
malformed one causes a build that reports success but produces nothing runnable.

### 5. Enable Actions on your fork

Go to your fork's **Actions** tab and click
*"I understand my workflows, go ahead and enable them."*

GitHub disables workflows on new forks. Until you click this, nothing you push
gets checked.

### 6. Pick a callsign

3–16 characters, letters and numbers, upper case. This is what appears on the
progress board — **your real name doesn't.**

```bash
echo "NIGHTJAR" > callsign.txt
```

### 7. Get a working environment

| Route | For | Start at |
|---|---|---|
| **Docker** | Windows 10/11, macOS (incl. Apple Silicon), any Linux. Nothing touches your partitions. | [`docker/`](docker/README.md) |
| **Ubuntu 24.04** | Dual boot or a spare machine. Faster, and what the team runs. | [`handbook/00`](handbook/00-install-ubuntu.md) |

On Windows or a Mac and unsure? **Use Docker.**

### 8. Check yourself

```bash
./tools/vanguard doctor    # is my machine set up correctly?
./tools/vanguard check     # is my work complete?
```

The same check runs automatically on every push to your fork. Anything you
haven't started is reported as *not started* and never counts against you.

## What's in here

| Directory | What it holds |
|---|---|
| [`sols/`](sols/README.md) | The four Sol sheets, in Markdown and as printable PDFs. |
| [`handbook/`](handbook/) | The reference material, from the terminal up. Each task tells you which parts you need. |
| [`docker/`](docker/) | The zero-install environment. |
| [`tools/`](tools/) | `vanguard doctor` and the readiness check. |
| [`markers/`](markers/) | Reference images used by one of the tasks. |
| [`vanguard_navigation/`](vanguard_navigation/) | A pre-built ROS 2 package you'll be asked to run, not write. |
| `src/` | **Where your work goes.** |

## Submitting

1. **Keep [`MISSION_LOG.md`](MISSION_LOG.md) as you go** — there's a template in the
   repo. It's the thing we read most carefully.
2. Work on your fork, committing as you go. **Small, frequent commits with real
   messages** — `add velocity publisher`, not `stuff`. We read these.
3. Open **one Pull Request** to this repository's `main`, titled
   `NAME [ID_NUMBER]` — e.g. `Ada Lovelace [2026A7PS0042H]`.
4. Keep pushing to that same PR. One PR carries all your work.

Sol sheets ask for a **screen recording under 90 seconds** with one thing
explained out loud. Upload to Google Drive (*Anyone with the link*) or YouTube
(*Unlisted*) and paste the link in your PR — **check it opens in a private
window.** Don't commit video files.

| | Date |
|---|---|
| **Opens** | 30 August 2026 |
| **Everything due** | **21 September 2026, 23:59 IST** |

## How you'll be judged

Not on how much you finish. Roughly, in order:

- **Understanding** — can you explain why your code works? Shortlisted recruits get
  a short walkthrough where we ask you to modify it live.
- **Correctness** — does it do the thing?
- **Engineering** — readable code, honest commits.
- **Honesty** — a clear account of what broke is worth more than pretending it didn't.

**The first task done properly, and understood, beats all of them rushed.**

Getting stuck is not failure. Hiding it is. Every one of us has lost a weekend to a
missing `source` line.

## Using AI

You **may** use Claude, ChatGPT, Copilot — we're an AI-leveraged team and
pretending otherwise would be silly.

One rule: **you must understand every line you submit.** In the walkthrough we'll
ask you to explain your code and change it in front of us. If you can't, it doesn't
count, however well it runs.

## Asking for help

Questions go in **[Issues](../../issues/new/choose)**, not DMs. Public, searchable,
answered once.

**Asking a good question is a skill we're explicitly looking for.** Include what
you tried, the exact command, the full error, and your `vanguard doctor` output.

**Evaluator:** Krithin Poola — Autonomous Lead, Project Vanguard.

---

## Mission patches

Every NASA mission has a patch. So do we — awarded, not given:

| Patch | Earned by |
|---|---|
| **FIRST LIGHT** | Sol 1 complete, and you can explain your node |
| **ROLLING** | Sol 2 complete — it drives, and comes back roughly where it started |
| **LINE OF SIGHT** | Sol 3 complete — a marker placed correctly in 3-D |
| **TERRA INCOGNITA** | Sol 4 — your rover explored an unknown arena unattended, and *stopped* |
| **CURIOUS** | You found the thing we didn't tell you about |
| **CAPCOM** | You answered someone else's Issue with something that actually helped |
| **ANOMALY REPORT** | You found a real bug in *our* instructions and told us |

The last three have nothing to do with code, and we mean them just as seriously.

## One more thing

Somewhere in this repository is something we haven't mentioned anywhere. Nothing
tells you where to look. Find it, open an Issue saying what it says, and there are
**brownie points** in it for you.

Perseverance's parachute had *Dare Mighty Things* woven into it in binary, and
Curiosity's wheels stamp "JPL" in Morse into the dirt of Mars with every turn.
Engineers hide things. Go and be curious.

---

*Dare mighty things.*
