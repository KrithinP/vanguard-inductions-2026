# Missions

All four are available now. **Do them in order** — each builds on the last.

| | Mission | What you'll build | Effort |
|---|---|---|---|
| **1** | [Boot Sequence](sol1/README.md) | A working workstation, and your first ROS 2 node | 6–8 h |
| **2** | [Rolling Chassis](sol2/README.md) | A four-wheel rover you can drive in simulation | 6–8 h |
| **3** | [Eyes](sol3/README.md) | A camera, and markers located in 3-D | 6–8 h |
| **4** | [The World Model](sol4/README.md) | ⭐ **Bonus** — sensors, maps and navigation | 5–7 h |

## How to approach this

**Mission 1 is the one that matters most.** Everything else stands on it, and it's
where the environment fights you. Get it solid before moving on.

**You are not expected to finish all four.** We'd far rather see Missions 1 and 2
done properly, with an honest log of what broke, than four rushed ones. Depth beats
coverage — the walkthrough will ask you to explain and modify your own code.

**Mission 4 is bonus.** It can only add to your evaluation, never subtract. Not
attempting it costs you nothing.

**Starting late is fine.** Nothing here is timed individually; there's one deadline
for everything, in the [README](../README.md).

## Checking yourself

```bash
./tools/vanguard check
```

Reports GO / NO-GO for each mission you've **started**. Missions you haven't begun
are ignored — they will never fail your build. The same check runs automatically on
every push to your fork.
