# 01 — The terminal

> **Time:** 45 minutes.
> **By the end:** you can move around your filesystem, read files, search inside
> them, and change what a file is allowed to do — without touching a mouse.

Open a terminal with `Ctrl+Alt+T`. You'll see something like:

```
krithin@rover-lab:~$
```

That's the **prompt**: your username, your machine name, then where you currently
are, then `$`. The `~` means your home directory (`/home/yourname`).

Robotics happens here. Not because we're purists — because a rover 500 m away over
a flaky radio link has no desktop. Every tool you'll use for the rest of your time
on this team is driven from a prompt like this one.

---

## Where am I, and what's here

```bash
pwd
```
```
/home/krithin
```

`pwd` = *print working directory*. It answers "where am I".

```bash
ls
```
```
Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos
```

`ls` = *list*. But it's hiding things:

```bash
ls -a
```
```
.  ..  .bashrc  .cache  .config  .profile  Desktop  Documents  Downloads ...
```

**Any file whose name starts with `.` is hidden from plain `ls`.** That's the whole
rule — there's no special "hidden" attribute like Windows has. `-a` means *all*.

> **Remember this one.** Part of Sol 1 depends on it.

Add `-l` for the long view:

```bash
ls -la
```
```
drwxr-xr-x 18 krithin krithin  4096 Aug 30 14:02 .
drwxr-xr-x  3 root    root     4096 Aug 12 09:11 ..
-rw-r--r--  1 krithin krithin  3771 Aug 12 09:11 .bashrc
drwxr-xr-x  2 krithin krithin  4096 Aug 30 13:55 Desktop
```

Reading a line: `d` at the start means directory, `-` means regular file. The next
nine characters are permissions (section below). Then owner, group, size, date, name.

`.` is *this directory*. `..` is *the one above*.

## Moving around

```bash
cd Downloads     # go into Downloads
pwd              # /home/krithin/Downloads
cd ..            # go back up one level
cd               # go home from anywhere
cd -             # go back to where you just were
```

**Press `Tab` constantly.** Type `cd Dow` then hit `Tab` — the shell completes it.
Hit `Tab` twice to see all the options. This is not a nicety; experienced people
type maybe half the characters you do, and make far fewer typos.

### Absolute vs relative paths

- **Absolute** starts with `/`: `/home/krithin/Downloads`. Always means the same
  place, from anywhere.
- **Relative** doesn't: `Downloads`, `../Pictures`. Means something different
  depending on where you are.

Most "file not found" errors in this induction are a relative path run from the
wrong directory. When something can't be found, run `pwd` first.

## Making, copying, moving, deleting

```bash
mkdir practice           # make a directory
cd practice
touch notes.txt          # create an empty file
cp notes.txt backup.txt  # copy
mv backup.txt old.txt    # rename (move is rename)
rm old.txt               # delete
cd ..
rm -r practice           # delete a directory and everything in it
```

> ⚠ **`rm` does not use a recycle bin.** There is no undo. `rm -rf` on the wrong
> path is how people lose a semester of work. Run `ls` on a path before you `rm` it.
> Never run `rm -rf /` or `rm -rf ~` — read any command someone gives you before
> pasting it.

## Reading files

```bash
cat notes.txt        # dump the whole file
head -20 notes.txt   # first 20 lines
tail -20 notes.txt   # last 20 lines
less notes.txt       # scroll it (arrows to move, q to quit)
```

`tail` is the one you'll live in — errors are always at the bottom.

## Finding things

```bash
find . -name "*.log"           # every .log file below here
find . -type d -name "src"     # every directory called src
```

## Searching inside files

This is the single most useful command in this document.

```bash
grep "error" robot.log            # lines containing "error"
grep -i "error" robot.log         # ignore upper/lower case
grep -n "error" robot.log         # show line numbers
grep -r "error" logs/             # search every file under logs/
grep -rn "FRAGMENT" .             # recursive, with line numbers, from here
```

`grep -r` searches a whole directory tree. When you know *what* you're looking for
but not *which file* it's in, this is the answer.

## Pipes — connecting commands

The `|` character takes one command's output and feeds it to the next.

```bash
ls -la | grep "Aug"        # only lines mentioning Aug
cat robot.log | wc -l      # count the lines
history | grep colcon      # which colcon commands have I run before?
```

Chain as many as you like:

```bash
cat robot.log | grep -i error | tail -5
```

*Read the log, keep only error lines, show the last five.*

## Permissions and `chmod`

Back to that `-rw-r--r--`. After the first character, it's three groups of three:

```
 rw-   r--   r--
owner group everyone
```

`r` read, `w` write, `x` execute. A script **cannot be run unless it has `x`**,
no matter what's inside it.

```bash
ls -l script.sh
```
```
-rw-r--r-- 1 krithin krithin 117 Aug 30 15:37 script.sh
```
```bash
./script.sh
```
```
bash: ./script.sh: Permission denied
```

Fix it:

```bash
chmod +x script.sh
./script.sh
```

`chmod +x` = *change mode, add execute*. You'll do this constantly.

> **`./` matters.** `script.sh` alone tells the shell to look for an installed
> program of that name. `./script.sh` says "the one in this directory, right here".

## Archives

```bash
tar czf stuff.tar.gz mydir/    # compress a directory
tar xzf stuff.tar.gz           # extract it
tar tzf stuff.tar.gz           # list contents without extracting
```

Remember it as **e**x**t**ract = `x`, **c**reate = `c`.

## Hashing

```bash
echo -n "hello" | sha256sum
```
```
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824  -
```

A hash is a fixed-length fingerprint of some input. Same input, same hash, always.
`-n` on `echo` means *don't add a newline* — with it you'd get a different hash,
which is exactly the kind of detail that bites people.

Trim it with `cut`:

```bash
echo -n "hello" | sha256sum | cut -c1-16
```
```
2cf24dba5fb0a30e
```

`cut -c1-16` = keep characters 1 to 16.

---

## Cheat sheet

| Need | Command |
|---|---|
| Where am I | `pwd` |
| What's here (incl. hidden) | `ls -la` |
| Go somewhere | `cd path` |
| Go home / go back | `cd` / `cd -` |
| Make a directory | `mkdir name` |
| Read a file | `cat` `head` `tail` `less` |
| Find a file by name | `find . -name "pattern"` |
| Find text inside files | `grep -rn "text" .` |
| Make runnable | `chmod +x file` |
| Extract an archive | `tar xzf file.tar.gz` |
| Fingerprint some text | `echo -n "x" \| sha256sum` |
| Stop a running program | `Ctrl+C` |
| Clear the screen | `clear` |

---

You now have everything you need for the `.mission/` directory in Sol 1.
Go and try it before continuing — it's more fun than reading.

Next: [`02-apt.md`](02-apt.md).
