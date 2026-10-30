# General: the things worth knowing

The page to read first. It covers the terminal, how NixOS is different from
every other Linux, every command this config gives you, and where things
live on disk. No previous knowledge assumed.

## Contents

- [1. The terminal](#1-the-terminal)
  - [Opening one, and what the prompt tells you](#opening-one-and-what-the-prompt-tells-you)
  - [Keys that save you typing](#keys-that-save-you-typing)
  - [The twenty commands that cover almost everything](#the-twenty-commands-that-cover-almost-everything)
  - [Paths: where am I, and what is `~`](#paths-where-am-i-and-what-is-)
  - [Pipes and redirects](#pipes-and-redirects)
  - [sudo](#sudo)
  - [When you don't know a command](#when-you-dont-know-a-command)
- [2. How NixOS thinks](#2-how-nixos-thinks)
  - [The repo *is* the system](#the-repo-is-the-system)
  - [Generations: every rebuild keeps the old system](#generations-every-rebuild-keeps-the-old-system)
  - [The Nix store, and why `/usr/bin` is empty](#the-nix-store-and-why-usrbin-is-empty)
  - [There is no "install a package"](#there-is-no-install-a-package)
  - [Trying a program without installing it](#trying-a-program-without-installing-it)
  - [Running a program you downloaded](#running-a-program-you-downloaded)
- [3. The flakeos commands](#3-the-flakeos-commands)
  - [The five Nix aliases](#the-five-nix-aliases)
  - [Which one when](#which-one-when)
  - [The logs folder](#the-logs-folder)
  - [The helper commands](#the-helper-commands)
- [4. The daily loop](#4-the-daily-loop)
- [5. Looking at your machine](#5-looking-at-your-machine)
- [6. Where things live](#6-where-things-live)
- [7. Which app opens which file](#7-which-app-opens-which-file)
- [8. Small things that are nice to know](#8-small-things-that-are-nice-to-know)

---

## 1. The terminal

### Opening one, and what the prompt tells you

**Mod+Return** opens alacritty, the terminal. (**Mod** is the Windows key.)

The shell inside it is **zsh**. It greets you with a two-line prompt:

```
  slider@zeus    ~/flakeos
 ❯
```

| part | means |
|---|---|
| `slider@zeus` | who you are, and which machine you are on. Handy when you are logged into the other one |
| `~/flakeos` | the folder you are *in* right now. Every command you type acts here unless you give it a path |
| `❯` | type here. It is **green** when the last command worked and **red** when it failed — the quickest error check there is |

Deep folders are shortened to the last three parts: `…/a/b/c`.

If you ever end up on the plain text console (Ctrl+Alt+F2, or after a logout),
the prompt is the same information without the decorations: `slider@zeus ~/dir`
and a green or red `>`.

### Keys that save you typing

| key | does |
|---|---|
| **Tab** | completes a file, folder or command name. Press it constantly — it is also how you check a name exists |
| **Tab Tab** | nothing completed? Pressing again lists the possibilities |
| **Up / Down** | walk through the commands you typed before (they survive reboots, 50000 of them) |
| **Ctrl+R** | search your old commands: press it, type a few letters of the command, Enter |
| **Ctrl+C** | stop the command that is running right now |
| **Ctrl+L** | clear the screen |
| **Ctrl+Left / Ctrl+Right** | jump a word at a time in the line you are typing |
| **Home / End** | start / end of the line |
| **Ctrl+Shift+C / Ctrl+Shift+V** | copy / paste. Plain Ctrl+C would stop the command instead |
| **Ctrl+D** | close the terminal (same as typing `exit`) |

Two zsh conveniences this config switches on:

- **Typing a folder name alone changes into it**: `~/flakeos` works, no `cd`
  needed (`auto_cd`).
- **A command starting with a space is not remembered** in the history, for
  the rare command with a password in it (`hist_ignore_space`).

### The twenty commands that cover almost everything

| command | does | example |
|---|---|---|
| `cd <folder>` | go into a folder | `cd ~/flakeos` |
| `cd ..` | go up one level | |
| `cd -` | back to the folder you were in before | |
| `ls` | list the files here | |
| `ll` | list them with sizes, dates and the hidden ones (an alias for `ls -lah`) | |
| `cat <file>` | print a file onto the screen | `cat flake.nix` |
| `bat <file>` | the nicer `cat`: colours, line numbers, and it pages long files (**q** quits) | `bat flake.nix` |
| `cp <from> <to>` | copy a file | `cp a.nix b.nix` |
| `cp -r <from> <to>` | copy a whole folder (`-r` = recursive; without it `cp` refuses folders) | `cp -r blueprints/programs/plain modules/programs/pinta` |
| `mv <old> <new>` | rename, or move somewhere else | `mv example.nix pinta.nix` |
| `rm <file>` | delete a file. **There is no trash — it is gone** | |
| `rm -r <folder>` | delete a folder and everything in it | |
| `mkdir -p <folder>` | create a folder (`-p`: also the folders above it, and no complaint if it exists) | `mkdir -p ~/Projects/test` |
| `grep -rn <word> <folder>` | find a word in files: `-r` also in subfolders, `-n` with line numbers | `grep -rn noctalia modules` |
| `find <folder> -name "<pattern>"` | find files by name | `find ~ -name "*.jpg"` |
| `less <file>` | read a long file: arrows scroll, `/word` searches, **q** quits | |
| `man <command>` | the full manual of a command (q quits) | `man wpctl` |
| `<command> --help` | the short version, usually enough | `mpv --help` |
| `df -h` | how full the disks are (`-h` = human-readable sizes) | |
| `free -h` | how much RAM is in use | |
| `which <command>` | where a command actually comes from | `which niri` |

Three small things this config adds on top of plain zsh:

- **`ll`** is `ls -lah`, and `ls` and `grep` print in colour.
- **`bat`** is installed next to `cat`. Same job, but it colours Nix,
  Markdown and shell files and pages anything long. `bat flake.nix` is nicer
  than `cat flake.nix` every time.
- **Grey ghost text** appears as you type: zsh suggesting the last command
  you typed that starts the same way. Press **Right arrow** to accept it, or
  keep typing to ignore it. What you type is coloured too — a command name
  that stays red does not exist.

### Paths: where am I, and what is `~`

- `~` is your home folder. `~/flakeos` is `/home/slider/flakeos`.
- A path starting with `/` is **absolute**: it means the same thing from
  anywhere. `/etc/wallpapers` is always `/etc/wallpapers`.
- A path *not* starting with `/` is **relative to the folder you are in**.
  `modules/grouped` means "the folder `modules/grouped` inside here". That is
  why every guide starts with `cd ~/flakeos` — otherwise the relative paths
  in it point nowhere.
- `.` is the folder you are in, `..` is the one above it.
- Names are **case sensitive**: `Pinta` and `pinta` are two different things.
- `*` stands for "anything": `ls *.nix` lists every file ending in `.nix`,
  `rm logs/*` deletes everything in `logs/`.

Lost? `pwd` prints the folder you are in (the prompt shows it too).

### Pipes and redirects

Three symbols do a surprising amount of work:

| written | means | example |
|---|---|---|
| `a \| b` | a **pipe**: send the output of `a` into `b` instead of onto the screen | `ls /nix/store \| grep firefox` |
| `a > file` | write the output of `a` into a file, **replacing** what was in it | `niri msg windows > /tmp/windows.txt` |
| `a >> file` | the same, but **append** to the end | |
| `a 2>&1 \| b` | also send the *error* output through the pipe (many programs print errors on a separate channel) | `nrs 2>&1 \| grep error` |

A pipe into `grep` is the single most useful thing here: it turns a wall of
output into the three lines you wanted.

### sudo

Some things need administrator rights: installing a new system version,
restarting a system service, mounting a drive. You get them by putting `sudo`
in front of the command, and typing *your own* password.

```sh
sudo systemctl restart openrgb
```

- There is **no root account** on this machine. The install ran with
  `--no-root-passwd`, so root is locked: nobody can log in as root and `su`
  does not work. `sudo` with your password is the only way, which is one
  password less to lose.
- `sudo` remembers your password for a few minutes, so a second command right
  after does not ask again.
- You can do this because your user is in the group `wheel`
  (`modules/users/slider.nix`).

### When you don't know a command

- `man <command>` — the manual. Long but complete. `/word` searches in it.
- `<command> --help` — the one-screen version.
- `which <command>` — proves whether it exists at all.
- `nix search nixpkgs <word>` — "is there a program for…?" (see below).

---

## 2. How NixOS thinks

This is the part that is genuinely different, and the part worth
understanding properly. Everything else follows from it.

### The repo *is* the system

On Ubuntu or Arch, you install things with a package manager and the system
slowly becomes a pile of decisions you have forgotten. There is no file that
says what the machine is.

Here there is: **`~/flakeos` is the complete description of this computer.**
Every program, every setting, the keyboard layout, the wallpapers, the key
binds. Nothing is installed by hand. You edit a file, then run:

```sh
nrs
```

and NixOS builds a whole new system from the repo and switches to it. Two
consequences worth taking seriously:

- **You can read your own machine.** Why is Bluetooth off at boot on the
  laptop? `grep -rn bluetooth modules/hosts/hermes/`.
- **Two machines from one repo.** zeus and hermes build from the same files;
  each picks what it gets in `modules/hosts/<name>/<name>.nix`.

One catch, and it bites everyone once: **the flake only sees files that git
knows about.** A brand new file that you did not `git add` is silently
ignored — no error, your change just does not happen.

```sh
cd ~/flakeos
```
```sh
git add -A
```

### Generations: every rebuild keeps the old system

A rebuild does not modify your system. It *builds a new one next to it* and
then points at the new one. The old one stays on disk, and in the boot menu.
Each of those is a **generation**.

This is the safety net behind everything in this wiki. A bad change costs you
a reboot, never the machine.

- List them:
  ```sh
  nixos-rebuild list-generations
  ```
- Go back to an older one: **reboot**, and in the boot menu (shown for 5
  seconds) pick an older entry.
- The last 30 are kept in the boot menu, and anything older than 30 days is
  deleted automatically once a week (`modules/system/nix.nix`).

Not in a generation: your home folder, and your password. Those are normal
files, and rolling back does not touch them.

### The Nix store, and why `/usr/bin` is empty

Every program lives in `/nix/store`, in its own folder, with a hash in the
name:

```
/nix/store/9k3h…-firefox-144.0/bin/firefox
```

The hash is built from everything that went into it — the source, the
compiler, every library. So two different versions of a program can sit side
by side without a fight, and a program can never accidentally pick up the
wrong library.

What this means in practice:

- `/usr/bin` does not exist, and `/etc` is mostly read-only links into the
  store. **Editing a file in `/etc` by hand does nothing** — the next rebuild
  overwrites it. The file to edit is in `~/flakeos`.
- A program you downloaded from a website expects `/usr/lib` and friends, so
  it will not just run. See [Running a program you downloaded](#running-a-program-you-downloaded).
- `which firefox` shows you a store path. That is normal, not a problem.
- The store gets big. `ncg` cleans it (see below).

### There is no "install a package"

There is no `apt install`. To add a program you add a few lines to the repo
and rebuild. The whole procedure, with copy-paste templates for every kind of
program, is [blueprints.md](blueprints.md).

To find out what a thing is called:

- The website: https://search.nixos.org/packages — search, and the name you
  need is the one after `pkgs.`
- Or in a terminal:
  ```sh
  nix search nixpkgs pinta
  ```
- For *system* settings (services, hardware, printing) the equivalent is
  https://search.nixos.org/options — every option you can write in a module
  is listed there with its description.

### Trying a program without installing it

This is NixOS at its nicest. Run a program once, without touching your
system, and it is gone when you close it:

```sh
nix run nixpkgs#pinta
```

A shell with some tools in it, until you type `exit`:

```sh
nix shell nixpkgs#imagemagick nixpkgs#ffmpeg
```

And one that only exists here: every **wrapped** program in this repo is also
a package of the flake, so you can run one straight from the repo, with its
config, without rebuilding:

```sh
cd ~/flakeos
```
```sh
nix run .#alacritty
```

That is the quickest way to try a config change: edit the file, `nix run
.#<program>`, look, decide, *then* `nrs`. It also works on any other machine
that has Nix installed, which is a side effect of wrapping and an oddly
satisfying one.

### Running a program you downloaded

An AppImage, a GOG installer, a game from itch.io, a vendor SDK: these are
built for ordinary distributions and have the path of their loader baked in,
which on NixOS does not exist. Normally you get:

```
cannot execute: required file not found
```

This config has **nix-ld** switched on (`modules/system/nix-ld.nix`), which
puts a real loader there plus a pool of the libraries such programs usually
want (graphics, sound, GTK, Electron). So most downloaded 64-bit binaries
just run:

```sh
chmod +x ./SomeProgram.AppImage
```
```sh
./SomeProgram.AppImage
```

When that is not enough — the program wants actual `/usr/share/...` files, or
it is 32-bit — put `steam-run` in front. It gives the program a fake ordinary
Linux to live in:

```sh
steam-run ./thatprogram
```

---

## 3. The flakeos commands

### The five Nix aliases

These are defined in `modules/programs/zsh/zshrc` and work from any folder.
They always build the config whose name matches this machine's hostname, so
the same command is right on zeus and on hermes.

| command | does |
|---|---|
| `nrs` | **rebuild** the system from `~/flakeos` and switch to it right away |
| `nrb` | rebuild, but only switch at the **next boot**. For big changes |
| `nup` | **update**: fetch the newest version of everything, build it, use it at the next boot. If the build fails, the old versions are put back and nothing changed |
| `ndb` | **dry build**: check *this* machine's config for errors and list what a rebuild would build and download, without building it. No password needed |
| `nck` | check **every** host and module in the flake for errors, without building anything |
| `ncg` | delete system versions older than 30 days, to free disk space |

### Which one when

- **Changed a file?** `nrs`. That is the normal one.
- **Changed a lot, or touched something that sounds risky?** `ndb` first. It
  reads the whole config and stops at the point where it would start
  building, so a typo or a wrong option name shows up in seconds, without a
  password. It also prints what *would* be downloaded, which tells you how
  big a job you are starting.
- **About to push to the other machine?** `nck`. `ndb` only checks this
  machine; `nck` checks both hosts and every module, so it catches breaking
  hermes while sitting at zeus.
- **Updating?** `nup`, then reboot. The whole story, including what can go
  wrong and the three ways back, is [updating.md](updating.md).
- **Disk getting full?** `ncg`. Not normally needed — a weekly job does the
  same thing (`modules/system/nix.nix`).
- **After a kernel update, or a change you don't trust?** `nrb`, then reboot
  when you are ready. The running system is not touched until then.

Neither `ndb` nor `nck` can find a problem that only appears while a package
is being *compiled*. So a rebuild can still fail after a clean check — and
when it does, it fails during the build and your running system is untouched.

Formatting, while you are in the repo:

```sh
nix fmt .
```

That tidies every Nix file in the repo (the `.` is needed). Purely cosmetic.

### The logs folder

Every one of those aliases shows its output on screen **and** saves it to a
file:

```
~/flakeos/logs/rebuild_2026-10-30-14:03:22.log
~/flakeos/logs/update_2026-10-28-21:02:11.log
```

The last line a command prints is the path of its own log. This exists for
exactly one situation: a wall of red text scrolled past and you want to read
the beginning of it.

```sh
ll ~/flakeos/logs
```
```sh
cat ~/flakeos/logs/rebuild_2026-10-30-14:03:22.log
```

`logs/` is ignored by git, so these files never leave the machine. Delete them
whenever you like:

```sh
rm ~/flakeos/logs/*
```

### The helper commands

Two commands exist to solve one problem: *you changed something in a program's
own settings window, and you want it in the repo so the next machine starts
out that way.*

| command | for |
|---|---|
| `noctalia-changes` | the bar, launcher and notifications. See [noctalia.md](noctalia.md) |
| `dconf-changes` | GTK apps with no config file: rnote, Shortwave, virt-manager. See [settings.md](settings.md) |

Both show you what you changed when run with no arguments, and write it into
the repo with `--save`. Neither one touches anything until you say `--save`.

---

## 4. The daily loop

Almost everything you will ever do is this:

1. **Open the repo.** Press **Mod+Z** and open `~/flakeos`, or:
   ```sh
   zeditor ~/flakeos
   ```
   Zed knows Nix, completes NixOS option names, and has a git panel down the
   left for seeing and undoing what you changed.
2. **Change a file.** Which one? The table in the
   [main README](../README.md#where-do-i-change) answers that for everything
   in the system.
3. **Made a *new* file?** Tell git, or the flake will not see it:
   ```sh
   cd ~/flakeos
   ```
   ```sh
   git add -A
   ```
4. **Rebuild:**
   ```sh
   nrs
   ```
5. **Reopen the programs you changed.** A program that was already running
   keeps its old config. For the bar, see [noctalia.md](noctalia.md) — there
   is a two-line restart that avoids logging out.
6. **Happy with it?** Commit, so you can always get back to it:
   ```sh
   git add -A
   ```
   ```sh
   git commit -m "what I changed"
   ```
   See [git.md](git.md).

A change that does not show up is nearly always step 3 or step 5.

---

## 5. Looking at your machine

| command | tells you |
|---|---|
| `fastfetch` | the showing-off summary: kernel, uptime, packages, GPU, RAM |
| `btop` | live CPU, RAM, disk, network and processes. **q** quits, click around with the mouse |
| `df -h` | how full each disk is |
| `du -sh <folder>` | how big one folder is (`du -sh ~/*` for a breakdown of your home) |
| `free -h` | RAM and zram usage |
| `lsblk` | the disks and their partitions |
| `lspci` | the hardware on the PCI bus (graphics card, network, controllers) |
| `lsusb` | what is plugged into USB |
| `vulkaninfo --summary` | is the graphics driver working properly? |
| `nixos-rebuild list-generations` | every system version you can boot back into |
| `niri msg windows` | every open window with its app ID (needed for window rules) |
| `wpctl status` | the sound devices PipeWire knows about |
| `systemctl status <service>` | is a system service running? (q quits) |
| `journalctl -b -e` | everything the system logged since this boot |

The last two are the start of [troubleshoot.md](troubleshoot.md), which is
entirely about reading logs.

---

## 6. Where things live

| path | what it is |
|---|---|
| `~/flakeos` | **the system.** Your repo. Everything you edit |
| `~/flakeos/logs/` | output of the last rebuilds and updates (ignored by git) |
| `~/flakeos/wallpapers/` | your wallpapers. Add one, `git add -A`, `nrs`, then Mod+W |
| `~/flakeos/wiki/` | this wiki |
| `/etc/wallpapers` | where the wallpapers are installed to. Don't edit; it comes from the repo |
| `/nix/store` | every program and config, read-only. Never edit, never delete by hand |
| `/run/current-system` | a link to the system version you are running right now |
| `~/.config/` | settings of programs that are *not* wrapped (Firefox is here, as `~/.mozilla`) |
| `~/.local/state/noctalia/settings.toml` | what you changed in noctalia's settings window |
| `~/.config/dconf/user` | what you changed in a GTK app that has no config file |
| `~/.local/state/zsh/history` | your command history |
| `~/Pictures/Screenshots` | where Mod+S puts screenshots |
| `~/.ssh/id_ed25519` | your GitHub key. Never share it, never put it in the repo |
| `/mnt/data` | the 1.9 TB data drive (**zeus only**). Not erased by a reinstall |
| `/var/lib/libvirt/images` | virtual machine disks. Not in the repo, survive rebuilds |

Standard folders — `~/Downloads`, `~/Pictures`, `~/Videos`, `~/Documents` —
are created at login if missing (`modules/system/xdg.nix`).

## 7. Which app opens which file

Set per program, in each program's own module (`xdg.mime.defaultApplications`):

| files | open in |
|---|---|
| videos, music | mpv |
| images | imv |
| folders | Thunar |
| archives (zip, 7z, rar, tar) | xarchiver |
| web links, HTML, PDFs | Firefox |
| text files | Zed |
| office documents | LibreOffice |

Check what a type is actually set to:

```sh
xdg-mime query default image/png
```

And what type a given file is:

```sh
xdg-mime query filetype holiday.png
```

To change one, see "Default app for a file type" in
[blueprints.md](blueprints.md#extras-default-apps-and-palette-colours).

## 8. Small things that are nice to know

- **Everything has a key bind, and Mod+BackSpace shows them all.** That is
  the single most useful key on the machine. The full list with explanations
  is [niri.md](niri.md).
- **`bat` instead of `cat`** for anything you actually want to read: colours,
  line numbers, and it pages long files (**q** quits, arrows scroll).
- **A game or VM swallowing your shortcuts?** **Mod+Escape** gives them back.
- **Two browsers on purpose.** Firefox for everything (Mod+B); Brave
  (Mod+Shift+B) only for sites that talk to hardware, which Firefox cannot do
  at all.
- **`claude` in a terminal** is Claude Code, the AI agent. It can read and
  edit this repo with you.
- **`fresh <file>`** is a terminal text editor with menus and a mouse, for
  when you are on the text console with no desktop. Also `nano <file>`, which
  is simpler: Ctrl+O saves, Ctrl+X quits.
- **The `Autoclicker` in the launcher** clicks for you, in every window. See
  [hardware.md](hardware.md#the-autoclicker).
- **A rebuild never half-happens.** Either it builds and switches, or it
  fails and your system is exactly as it was. There is no broken middle
  state to clean up.
- **Nothing updates by itself.** Not the kernel, not Firefox, not anything.
  You update when you run `nup`, which means a machine you do not touch for
  three months is the same machine when you come back.
