# Docker — the escape hatch

For recruits whose laptop genuinely cannot dual-boot or run a VM. A full Linux
desktop with ROS 2 Jazzy and Gazebo Harmonic, in your browser.

> **This is a fallback, not a shortcut.** Installing your own environment is part
> of Sol 1 — you'll learn less here. Use it if you're blocked, not to skip ahead.
> If you use it, say so in your `MISSION_LOG.md`. That's not held against you.

## Running it

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
(Windows/macOS) or Docker Engine + Compose (Linux). Then:

```bash
cd docker
docker compose up -d
```

Open **<http://localhost:8080>** — that's your Linux desktop.

A terminal inside the container:

```bash
docker compose exec vanguard bash
```

The repo's `src/` is mounted at `/root/vanguard_ws/src`, so you can edit files in
your normal editor on your laptop and build them inside the container.

Stop it with `docker compose down`. Your work in `src/` survives.

## Notes

- **Apple Silicon:** the image is multi-arch and runs natively.
- **Sections you can skip:** `handbook/00` and `handbook/04` — the environment is
  already built. **Read them anyway.** You'll be asked about `source` in the
  walkthrough, and the container won't answer for you.
- **Slow or blank desktop:** give Docker more RAM (Settings → Resources → 8 GB+).
- **Port 8080 in use:** change the left-hand number in `docker-compose.yml`.
