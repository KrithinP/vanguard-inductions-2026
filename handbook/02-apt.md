# 02 — Installing software with `apt`

> **Time:** 20 minutes.
> **By the end:** you understand what you're agreeing to when you paste a
> `sudo apt install` line off the internet.

On Windows you download a `.exe` and double-click it. Linux doesn't work that way.
Software comes from **repositories** — curated servers holding thousands of
packages — and a tool called `apt` fetches and installs from them.

This is better in a way that matters to you: one command updates everything on the
machine, and packages declare what they depend on, so `apt` installs those too.
ROS 2 is roughly 300 packages. You will never install them by hand.

## The two commands

```bash
sudo apt update
```

Refreshes the **catalogue** — asks every repository what versions it currently has.
It installs nothing. Run it before installing, or you'll be shopping from a stale list.

```bash
sudo apt install ros-jazzy-desktop
```

Actually downloads and installs, plus everything it depends on.

> **`update` ≠ `upgrade`.** `update` refreshes the list. `upgrade` installs newer
> versions of what you already have. Nearly everyone mixes these up once.

## What `sudo` means

`sudo` = *substitute user do*. It runs one command as the administrator (`root`).
Installing software changes files that belong to the whole system, so it needs
permission.

It'll ask for your password. **Nothing appears as you type — no dots, no stars.**
That's deliberate, not a broken keyboard. Type it and press Enter.

> **Warning.** `sudo` will do anything you ask, including destroying the machine. Never paste
> a `sudo` command you don't understand. If a StackOverflow answer says
> `sudo rm -rf /usr` — read it, understand it, then don't.

## Other things you'll use

```bash
apt search rviz                  # find a package (no sudo — read only)
apt show ros-jazzy-rviz2         # details about one
apt list --installed | grep ros  # what ROS packages do I have?
sudo apt remove <package>        # uninstall
sudo apt autoremove              # clean up orphaned dependencies
```

## Adding a repository

ROS 2 isn't in Ubuntu's default repositories, so in [`04-install-ros2.md`](04-install-ros2.md)
you'll add ROS's own. That's two steps:

1. **Add its signing key.** Every package is cryptographically signed. Your machine
   refuses packages it can't verify — this is what stops someone serving you a
   malicious "ROS".
2. **Add the repository URL** to `/etc/apt/sources.list.d/`.

You'll paste two long commands to do this. Now you know what they're for.

## `apt` vs `pip`

You'll use both.

| | `apt` | `pip` |
|---|---|---|
| Installs | System packages | Python packages only |
| Scope | Whole machine | Python |
| Use for | ROS 2, simulators, drivers | numpy, OpenCV, matplotlib |

On Ubuntu 24.04, `pip install` into the system Python is blocked by default —
you'll get `error: externally-managed-environment`. That's Ubuntu protecting itself.
For this induction, install into your user account:

```bash
pip install --user --break-system-packages opencv-contrib-python
```

The flag name is alarming and the risk here is essentially nil — you're installing
to your own home directory, not overwriting system files.

## When things go wrong

**`Could not get lock /var/lib/dpkg/lock-frontend`**
Something else is using apt — usually Ubuntu's automatic updater. Wait a minute and
retry. If it persists:
```bash
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock*
sudo dpkg --configure -a
```

**`Unable to locate package ros-jazzy-desktop`**
You skipped `sudo apt update`, or the ROS repository was never added. Go back to
[`04-install-ros2.md`](04-install-ros2.md).

**`NO_PUBKEY` / signature errors**
The signing key is missing or wrong. Redo the key step in `04`.

Next: [`03-bashrc-path-source.md`](03-bashrc-path-source.md) — the one that
confuses everyone.
