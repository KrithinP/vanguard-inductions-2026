# The Sols

```
   SOL 001 ──────── SOL 014 ──────── SOL 031 ──────── SOL 067
   boot             chassis          eyes             autonomy
   ▓▓▓▓▓▓           ▓▓▓▓▓▓           ▓▓▓▓▓▓           ▓▓▓▓▓▓▓▓▓▓▓
   guided           assembled        described        on your own
```

All four are here from the start. **Do them in order** — each builds on the last,
and Sol 1 is what everything else stands on.

| | Sol | What you'll build | Read | Print | Effort |
|---|---|---|---|---|---|
| **1** | Boot Sequence | A working workstation, and your first ROS 2 node | [sol1.md](sol1.md) | [Windows](sol1-windows.pdf) · [macOS](sol1-macos.pdf) · [Linux](sol1-linux.pdf) | 6–8 h |
| **2** | Rolling Chassis | A four-wheel rover you can drive in simulation | [sol2.md](sol2.md) | [PDF](sol2-rover.pdf) | 6–8 h |
| **3** | Eyes | A camera, and markers located in 3-D | [sol3.md](sol3.md) | [PDF](sol3-vision.pdf) | 6–8 h |
| **4** | Terra Incognita | ⭐ **Bonus** — a rover that explores on its own | [sol4.md](sol4.md) | [PDF](sol4-autonomy.pdf) | 12–18 h |

The Markdown and the PDF are the same content. Only Sol 1's sheet differs by
operating system; the rest are the same for everyone.

## The help thins out on purpose

| Sol | What you're given | What you write |
|---|---|---|
| **1** | A complete working node to read and copy | ~30 lines |
| **2** | The pieces, and a skeleton to assemble them | ~250 lines |
| **3** | The API, the traps, the failure modes — **no node** | ~250 lines |
| **4** | The algorithm **in prose. No code at all** | ~450–600 lines |

By Sol 4 you are doing the actual job: taking a clear description of a problem and
building the thing. If it feels hard, that's the design.

**Sol 4 is a bonus.** It can only add to your evaluation, never subtract.

## You are not expected to finish all four

Sol 1 alone, done properly and understood, is a perfectly good submission — and
counts for more than four rushed ones you can't explain.

Start at Sol 1. Get as far as you get. Be honest in your
[`MISSION_LOG.md`](../MISSION_LOG.md) about where you stopped and why.

## Checking yourself

```bash
./tools/vanguard check
```

Reports GO / NO-GO for each Sol you've **started**. Sols you haven't begun are
reported as *not started* and can never fail your build.
