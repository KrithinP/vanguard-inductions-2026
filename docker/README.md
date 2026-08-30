# Docker — run the whole environment in your browser

A complete Ubuntu desktop with ROS 2 Jazzy and Gazebo Harmonic, running in a
container, viewed through your web browser. **No dual boot, no VM, no partitioning.**

## Does this work on my machine?

| Your machine | Works? | Notes |
|---|---|---|
| **Windows 10 / 11** | ✅ | Docker Desktop with the WSL 2 backend (the default) |
| **macOS, Apple Silicon** (M1–M4) | ✅ | Runs **natively** on arm64 — no emulation |
| **macOS, Intel** | ✅ | |
| **Linux** (any distro) | ✅ | Docker Engine + Compose |
| **Ubuntu 24.04 natively** | — | You don't need this. Install ROS directly. |

The base image is multi-architecture, so Docker pulls the right build for your CPU
automatically. **You do not need Ubuntu, and you do not need to touch your disk
partitions.**

Requirements: **8 GB RAM** (16 GB comfortable), **~15 GB free disk**, and a browser.

## Setting it up

**1. Install Docker**

- Windows / macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Linux: `sudo apt install docker.io docker-compose-v2` (then `sudo usermod -aG docker $USER` and log out and back in)

On Windows, Docker Desktop will ask to enable WSL 2. Say yes.

**2. Start it**

```bash
cd docker
docker compose up -d --build
```

The first run builds the image. **Expect 10–20 minutes** — it's downloading a full
Linux desktop plus ROS. It only happens once. Later starts take seconds.

**3. Open the desktop**

Go to **<http://localhost:8080>** in your browser.

That's a real Ubuntu desktop. Right-click it for a menu; there's a terminal in there.

**4. Check it works**

In a terminal on that desktop:

```bash
ros2 run turtlesim turtlesim_node
```

A window with a turtle should appear. If it does, you're ready.

## Day-to-day use

Get a terminal without using the browser desktop:

```bash
docker compose exec vanguard bash
```

Stop it (your work is kept):

```bash
docker compose down
```

### Where your files live

The repository's `src/` folder is mounted at `/root/vanguard_ws/src` inside the
container. **Edit files in your normal editor on your own machine** — VS Code,
whatever you like — and build and run them inside the container. Changes appear
instantly on both sides.

Anything you write **outside** `src/` inside the container is lost when the
container is removed. Keep your work in `src/`.

## Honest limitations

- **Simulation will be slower** than a native install. The container renders in
  software with no direct access to your graphics card. For the worlds in this
  induction that's fine; it is not what you'd use for serious work.
- **Sound doesn't work.** You don't need it.
- If your laptop has 8 GB RAM total, close Chrome before running the simulator.

## Using this instead of installing Ubuntu

Perfectly acceptable. Two things to know:

1. **You still have to read [`handbook/00`](../handbook/00-install-ubuntu.md) and
   [`handbook/04`](../handbook/04-install-ros2.md).** The container already has
   everything installed, so you can skip the *commands* — but the concepts,
   especially `source` and `.bashrc`, come up in the walkthrough and the container
   will not answer for you.
2. **Say so in your `MISSION_LOG.md`.** It's context for us, not a deduction.
   Nobody is marked down for using this.

## If it goes wrong

**`docker: command not found`** — Docker isn't installed, or on Windows you're in
a terminal that can't see it. Use PowerShell or the WSL terminal.

**`permission denied while trying to connect to the Docker daemon`** (Linux) —
```bash
sudo usermod -aG docker $USER
```
Then log out and back in completely.

**Port 8080 already in use** — change the left-hand number in
`docker-compose.yml`, e.g. `"8081:80"`, then use `localhost:8081`.

**Desktop is blank, grey, or won't load** — give it a minute after `up`. Then
check `docker compose ps`. If it's restarting, you're probably out of memory —
raise Docker's RAM limit (Docker Desktop → Settings → Resources → 8 GB+).

**Build fails partway** — usually a dropped network connection. Just run
`docker compose up -d --build` again; it resumes from where it stopped.

**Everything is unbearably slow** — check Docker Desktop's memory allocation, and
close other applications. If your machine has 4 GB RAM, this route won't be
comfortable; talk to us.

Still stuck? [Open an Issue](../../../issues/new/choose) with your OS, the exact
command, and the full error.
