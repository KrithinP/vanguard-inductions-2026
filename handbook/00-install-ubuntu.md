# 00 — Getting Ubuntu 24.04

> **Time:** 1–2 hours, most of it waiting for downloads.
> **You need:** a laptop, a USB stick (8 GB+), and about 60 GB of free disk space.

The team runs **Ubuntu 24.04 LTS**. Not 22.04, not 26.04, not Mint, not WSL for the
simulation work. Robotics software is fussy about versions in a way most software
isn't — a package built for 24.04 genuinely will not run on 26.04. Matching the
team exactly is the difference between "my code doesn't work" and "my code doesn't
work *and nobody can help me*".

You have three routes. **Read all three before choosing.**

> ###  On Windows or a Mac? Read this first.
>
> **You do not have to install Ubuntu at all.** Route C runs the whole environment
> in a container and shows you an Ubuntu desktop in your web browser — on Windows
> 10/11, on Intel and Apple Silicon Macs, and on any Linux. Nothing touches your
> disk partitions.
>
> It is fully supported and nobody is marked down for using it. If the idea of
> repartitioning your laptop makes you nervous, **skip to Route C** and get on with
> the actual robotics.

---

## Route A — Dual boot (recommended)

Ubuntu installed alongside Windows. You pick which one to start at boot.

**Why this one:** full speed, full GPU access, and it's what everyone on the team
runs. Gazebo needs real graphics performance and this is the only route that
reliably gives it to you.

**The honest downside:** it repartitions your disk. That is a real operation on
your real laptop. Done carefully it is safe and routine; done carelessly you can
lose your Windows install.

### Before you touch anything

1. **Back up your files.** Copy anything you care about to Google Drive or an
   external disk. Not "I'll be careful" — actually do it. Everyone who has ever
   lost data was being careful.
2. **Free up space in Windows.** You want 60 GB minimum, 100 GB if you can.
3. **Note your laptop's brand.** You'll need its boot-menu key in step 4.

### Steps

**1. Download the ISO.** Get `ubuntu-24.04-desktop-amd64.iso` from
<https://releases.ubuntu.com/24.04/>. It's about 6 GB.

**2. Write it to the USB stick.** Download [Rufus](https://rufus.ie) (Windows),
pick your USB stick, pick the ISO, press Start, accept the defaults. This erases
the USB stick.

**3. Turn off Fast Startup and BitLocker in Windows.**
Fast Startup leaves the disk in a half-shut-down state that Ubuntu cannot safely
resize. BitLocker encrypts it so nothing can.

- Fast Startup: Control Panel → Power Options → *Choose what the power buttons do*
  → *Change settings that are currently unavailable* → untick **Turn on fast startup**.
- BitLocker: Settings → Privacy & Security → Device encryption → **Off**.
  (If you don't see it, you don't have it. Fine.)

**4. Boot from the USB.** Restart, and as it powers on press the boot-menu key
repeatedly:

| Brand | Key |
|---|---|
| Dell | `F12` |
| HP | `F9` or `Esc` |
| Lenovo | `F12` or `Fn+F12` |
| Asus | `Esc` or `F8` |
| Acer | `F12` |
| MSI | `F11` |

Pick your USB stick from the list. Then choose **Try or Install Ubuntu**.

**5. Run the installer.** Defaults are fine, except one screen:

> When it asks **"How do you want to install Ubuntu?"**, choose
> **Install Ubuntu alongside Windows Boot Manager**.
>
> Do **not** choose *Erase disk and install Ubuntu*. That one deletes Windows.
> Read that screen twice. It is the only irreversible moment in this process.

Give Ubuntu at least **60 GB** on the slider. Then set your username and password —
**write the password down**, you'll type it constantly.

**6. Reboot and remove the USB.** You should now get a menu at startup letting you
choose Ubuntu or Windows. That menu is called GRUB.

> ### What just happened
> Your disk now has two operating systems on it, in separate partitions. They
> can't see into each other's space. Choosing at boot is the only switch — you
> can't run both at once. Windows is untouched and still there.

---

## Route B — Virtual machine

Ubuntu running *inside* a window on Windows or macOS.

**Why:** zero risk to your existing system, and you can delete it if it goes wrong.

**Why not:** Gazebo will be slow, sometimes unusably so. Fine for the first task. You may
struggle later.

Install [VirtualBox](https://www.virtualbox.org/) (free), create a new VM with the
Ubuntu 24.04 ISO, and give it **at least 8 GB RAM, 4 CPU cores, and 60 GB disk**.
Enable 3D acceleration in Settings → Display. Then install
**Guest Additions** from the VM's Devices menu — without it your window won't resize
and graphics will crawl.

## Route C — Docker

A full Ubuntu desktop with ROS and Gazebo already installed, running in a
container, viewed in your browser.

**Why:** works on Windows 10/11, macOS (Intel *and* Apple Silicon, natively) and
Linux. Nothing is repartitioned, nothing is at risk, and setup is two commands.
This is the route most people on Windows and Mac should take.

**Why not:** simulation renders in software, so it's slower than a native install.
For this induction that's fine.

**→ [`docker/README.md`](../docker/README.md)**

Two things if you take this route:

1. **Still read the rest of this handbook.** You can skip the install *commands*,
   but not the concepts — especially [`03`](03-bashrc-path-source.md). We ask about
   `source` in the walkthrough and the container won't answer for you.
2. **Mention it in your `MISSION_LOG.md`.** Context for us, not a deduction.

---

## Apple Silicon Macs (M1/M2/M3/M4)

Route A doesn't exist for you. **Route C is the recommended path** — the container
image is multi-architecture and runs natively on arm64, with no emulation penalty.
Route B works too, via [UTM](https://mac.getutm.app/) with the **arm64** Ubuntu
24.04 ISO.

---

## Before you move on

*(On Route C, open a terminal on the browser desktop instead of pressing
`Ctrl+Alt+T`, and expect `24.04` just the same.)*

Boot into Ubuntu, open a terminal (`Ctrl+Alt+T`) and run:

```bash
lsb_release -a
```

Expected output:

```
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.3 LTS
Release:        24.04
Codename:       noble
```

The point release (`.3`) may differ. **`Release: 24.04` must match.**

If it does — you're in. Next: [`01-terminal.md`](01-terminal.md).

## If it went wrong

**No boot menu appears, it goes straight to Windows.** Secure Boot or Fast Startup
is still on. Reboot into BIOS (usually `F2` or `Del`), find *Secure Boot*, disable
it, save and exit.

**"No bootable device" after installing.** The boot order changed. In BIOS, move
*ubuntu* above *Windows Boot Manager*.

**Wi-Fi doesn't work in Ubuntu.** Very common on Broadcom chipsets. Plug in
ethernet or tether your phone over USB, then:
```bash
sudo apt update && sudo apt install -y bcmwl-kernel-source
```

**The installer won't offer "alongside Windows".** Fast Startup or BitLocker is
still on, or the disk has no free space. Go back to step 3.

Still stuck? [Open an Issue](../../../issues/new/choose). Include your laptop model,
what you clicked, and a photo of the screen.
