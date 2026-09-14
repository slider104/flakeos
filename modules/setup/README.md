# Installing flakeos

This guide installs flakeos on a PC from scratch, step by step. You don't
need to know NixOS for it.

- Every command sits in its own box, so you can copy it. The line above
  says what it does. Read a step to the end before you type.
- The installer is text only: no mouse, no copy and paste. Keep this guide
  open on a phone or a second PC and type the commands.
- **The disk you pick in step 4 gets erased completely.** Other disks are
  not touched.

Reinstalling a machine that's already in the repo (like zeus)? Use the
short version: [Reinstalling a configured host](#reinstalling-a-configured-host-example-zeus).
New to the terminal? Read [Commands used in this guide](#commands-used-in-this-guide)
first.

## Contents

- [Commands used in this guide](#commands-used-in-this-guide)
1. [Boot the installer](#1-boot-the-installer)
2. [Get flakeos](#2-get-flakeos) (+ optional: [local only, without git](#optional-local-only-without-git))
3. [Pick your names](#3-pick-your-names)
4. [Describe your machine](#4-describe-your-machine-the-host)
5. [Add yourself](#5-add-yourself-the-user) (+ optional: [no gaming](#optional-smaller-first-install-no-gaming), [not German](#optional-not-german))
6. [Check the config](#6-check-the-config)
7. [Format the disk](#7-format-the-disk)
8. [Install](#8-install)
9. [First start](#9-first-start)
10. [Make it yours](#10-make-it-yours)
- Optional: [Your own GitHub repo](#optional-your-own-github-repo)
- [Reinstalling a configured host (example: zeus)](#reinstalling-a-configured-host-example-zeus)
- [When something goes wrong](#when-something-goes-wrong)

## What you need

- A PC with **UEFI** (every PC from the last ten years; in a virtual
  machine, switch EFI on). The boot loader, systemd-boot, needs it.
- A **USB stick** with 2 GB or more. It gets erased too.
- **Internet**: a cable works by itself, Wi-Fi needs one extra step.
- About an hour. Most of it is waiting for downloads.

## How the install works

A normal NixOS install starts with an empty config that you then fill in.
flakeos is the other way round: the whole system is already described in
this repo. You only add the two things that are unique to you:

- a **host**: your machine. Its hardware scan and which disk to use. A
  folder in `modules/hosts/`.
- a **user**: you. Name, groups, first password. A file in `modules/users/`.

After that, three tools do the work:

1. **disko** reads the disk layout from `modules/setup/disko.nix`, erases
   your disk, partitions and formats it exactly like that, and mounts it at
   `/mnt`.
2. **nixos-install** builds the complete system from the repo and writes it
   to `/mnt`, boot loader included.
3. At the end you copy the repo into your new home folder, so after the
   reboot you keep working on the same files in `~/flakeos`.

Nothing on the disk changes before step 7.

## Commands used in this guide

Good to know first:
- Names are case sensitive: `Mybox` and `mybox` are two different things.
- **Tab** completes file and folder names, so you rarely type them fully.
  The Up arrow brings back the last command.
- Paths without a `/` at the start are *relative*: `modules/hosts` means
  "the folder `modules/hosts` inside the folder I'm in right now". That's
  why step 2 ends with `cd /tmp/flakeos`.
- `~` is the home folder of whoever you are right now.

| command | does | example |
|---|---|---|
| `sudo -i` | become root (the administrator) until you close the console. The prompt then ends with `#` | |
| `cd <folder>` | go into a folder | `cd /tmp/flakeos` |
| `cp -r <from> <to>` | copy a folder with everything inside (`-r` = recursive) | `cp -r blueprints/hosts/example modules/hosts/$HOST` |
| `mv <old> <new>` | rename a file (or move it) | `mv …/example.nix …/$HOST.nix` |
| `mkdir -p <folder>` | create a folder (`-p`: also the folders above it, and no error if it exists) | `mkdir -p /mnt/home/$NAME` |
| `cat <file>` | show a file's content | `cat modules/users/$NAME.nix` |
| `ls -l <path>` | list files with details. For a link, the arrow `->` shows where it points | `ls -l $DISK` |
| `lsblk` | list disks and partitions | `lsblk -d -o NAME,SIZE,MODEL` |
| `grep <text> <file>` | show only the lines that contain the text | `grep device modules/hosts/$HOST/disko.nix` |
| `nano <file>` | a simple text editor. Ctrl+O saves, Ctrl+X quits | |
| `sed …` | find and replace text in a file, see [below](#sed-find-and-replace-in-a-file) | |
| `chown -R <user>:<group> <folder>` | make a user the owner of a folder and everything inside | `chown -R $NAME:users /home/$NAME` |
| `reboot` | restart the PC | |

Shell features the commands use:

| written | means | example |
|---|---|---|
| `HOST=mybox` | store the text `mybox` in the variable `HOST`. No spaces around `=` | `HOST=mybox` |
| `$HOST` | put the stored text in here. The console turns `modules/hosts/$HOST` into `modules/hosts/mybox` before running the command | `cd modules/hosts/$HOST` |
| `echo <text>` | print text, e.g. to check a variable | `echo $HOST $NAME` |
| `a \| b` | a *pipe*: the output of `a` goes into `b` instead of onto the screen | `ls -l /dev/disk/by-id/ \| grep -v part` (`-v`: only lines *without* "part") |
| `a > file` | write the output of `a` into a file. **Replaces** what was in it | `sed "…" slider.nix > $NAME.nix` |
| `{ a; b; c; } > file` | run several commands and write all their output into one file | the hardware scan in step 4 |
| `*.nix` | all files ending in `.nix` in that folder | `modules/hosts/$HOST/*.nix` |
| `'…'` | text in single quotes is taken exactly as written | `'s/"de"/"us"/'` |
| `"…"` | text in double quotes, but `$VARIABLES` inside are filled in | `"s/example/$HOST/g"` |

### sed: find and replace in a file

`sed` (stream editor) replaces text in a file without opening it. The
blueprints say `example` or `slider` wherever your names have to go, and
`sed` fixes every place at once, so none can be missed. The basic form:

```sh
sed -i 's/example/mybox/g' file.nix
```

| part | means |
|---|---|
| `-i` | "in place": change the file itself. Without `-i`, sed prints the changed text instead |
| `s` | substitute (replace) |
| `/example/` | the text to find |
| `mybox/` | the text to put in its place |
| `g` | every match in a line, not only the first one |

The four forms in this guide:

| command (shortened) | what's different |
|---|---|
| `sed -i "s/example/$HOST/g" modules/hosts/$HOST/*.nix` | **double quotes**, so `$HOST` becomes your hostname. In single quotes, sed would write the letters `$HOST` into the file. `*.nix` does all three files at once |
| `sed -i "s\|/dev/disk/by-id/CHANGE-ME\|$DISK\|" …/disko.nix` | **`\|` instead of `/`** between the parts: the text itself is full of `/`, which would confuse sed. Any sign works as long as it's the same three times |
| `sed "s/slider/$NAME/g" modules/users/slider.nix > modules/users/$NAME.nix` | **no `-i`**: `slider.nix` stays as it is, and `>` writes the changed copy into a new file |
| `sed -i '/^ *gaming$/d' …/$HOST.nix` | **`d` = delete** every line that matches. `^` = line start, ` *` = any number of spaces, `$` = line end. So: a line that is only `gaming` (with its indent) |

---

## 1. Boot the installer

- Download the **Minimal ISO image** from https://nixos.org/download/
  (section NixOS, 64-bit Intel/AMD).
- Write it to the USB stick: on Linux with Fedora Media Writer (on
  flakeos: `mediawriter`), on Windows with Rufus.
- Plug the stick in, switch the PC on and open its boot menu. The key
  differs per PC: F12, F11, F8 or Esc. Pick the USB stick.
- In the NixOS menu, take the first entry.
- You land in a text console, logged in as the user `nixos`. Become the
  administrator (root) for the whole install:
  ```sh
  sudo -i
  ```
- Optional: German keyboard. The default is US:
  ```sh
  loadkeys de
  ```
- Optional: twice the font size, for small or 4K screens:
  ```sh
  setfont -d
  ```
- Optional: Wi-Fi. Pick "Activate a connection", your network, type the
  password, then "Back" and "Quit":
  ```sh
  nmtui
  ```
- Check that you're online. Three answers mean it works:
  ```sh
  ping -c 3 nixos.org
  ```

## 2. Get flakeos

**The idea:** the installer runs completely in RAM, so `/tmp` is a fine
place for the repo during the install. `git clone` downloads it with its
whole history.

- Download the repo:
  ```sh
  git clone https://github.com/slider104/flakeos.git /tmp/flakeos
  ```
- Go into it. All following commands run from here:
  ```sh
  cd /tmp/flakeos
  ```

### Optional: local only, without git

**The idea:** the repo is a *git* repository. Git records every change
(history, undo, "what did I change?") and can upload it to GitHub. Nix
flakes use git as well: inside a git repo, the flake only sees files git
knows about. That's why new files need `git add`.

If you don't want any of that, only your files on this PC, delete git's
data. Then the flake simply takes every file in the folder.

- \+ never `git add`, no "Git tree is dirty" warnings
- − no history: no undo, no `git diff`. Backups are up to you.
- − no Zed git panel, no GitHub; "Saving changes to GitHub" in the main
  README doesn't apply
- − `.gitignore` stops working: every rebuild copies the whole folder into
  the Nix store, `logs/` included. It doesn't change your system; just
  delete old logs now and then.

Steps:

- Delete git's data (history, the link to GitHub) and its ignore list:
  ```sh
  rm -rf .git .gitignore
  ```
- From now on, **skip every `git add -A`** in this guide and in the other
  READMEs.

Changed your mind later? `git init` in `~/flakeos` starts a new, empty
history.

## 3. Pick your names

**The idea:** you need two names: one for the machine (the *hostname*) and
one for you (the *user name*, your login). We store them in two shell
variables, `HOST` and `NAME`. Every later command uses `$HOST` and `$NAME`,
so you can type the commands exactly as they are written.

Both names: lowercase letters, digits and `-`, starting with a letter.

- The machine's name, e.g. `mybox`:
  ```sh
  HOST=mybox
  ```
- Your user name, e.g. `alice`:
  ```sh
  NAME=alice
  ```
- Check both:
  ```sh
  echo $HOST $NAME
  ```

The variables only live in this console. After a reboot, or in a second
console, set them again.

## 4. Describe your machine (the host)

**The idea:** a host is a folder `modules/hosts/<name>/` with three files:

- `<name>.nix`: what the machine gets (bundles like `desktop` and
  `gaming`, users, the hostname)
- `hardware.nix`: what the kernel needs to boot on this hardware
- `disko.nix`: which disk to install to

You copy the host *blueprint* (a template) and fill in these three files.

- Copy the host blueprint as your host folder:
  ```sh
  cp -r blueprints/hosts/example modules/hosts/$HOST
  ```
- Name the main file after the machine:
  ```sh
  mv modules/hosts/$HOST/example.nix modules/hosts/$HOST/$HOST.nix
  ```
- Replace the placeholder `example` with your hostname, in all three files:
  ```sh
  sed -i "s/example/$HOST/g" modules/hosts/$HOST/*.nix
  ```
- The blueprint gives the machine to the user `slider` (in the user list
  and the automatic login). Make that you:
  ```sh
  sed -i "s/slider/$NAME/g" modules/hosts/$HOST/$HOST.nix
  ```

### The hardware scan

**The idea:** `nixos-generate-config` looks at this PC (disk controller,
USB, CPU) and prints a small Nix module with what the kernel needs.
`--no-filesystems` leaves out disks and mount points, because `disko.nix`
takes care of those.

In flakeos, every file publishes its module under a name, so the command
below wraps the scan in `{ flake.nixosModules.<host>-hardware = <scan>; }`.
`grep -v '^#'` drops the scan's comment lines ("Do not modify this file…"),
which don't apply here.

- Scan and write `hardware.nix`:
  ```sh
  { echo "{ flake.nixosModules.$HOST-hardware ="; nixos-generate-config --show-hardware-config --no-filesystems | grep -v '^#'; echo "; }"; } > modules/hosts/$HOST/hardware.nix
  ```
- Look at it. It should start with `{ flake.nixosModules.mybox-hardware =`
  and end with `; }`:
  ```sh
  cat modules/hosts/$HOST/hardware.nix
  ```

### Which disk

**The idea:** Linux calls disks `/dev/nvme0n1` or `/dev/sda`, but those
names can swap between boots (on zeus they did). The names in
`/dev/disk/by-id/` are built from the disk's model and serial number and
never change. `disko.nix` uses one of those, so the wrong disk can never be
erased by accident.

- List the disks with size and model, to see which one is your system disk:
  ```sh
  lsblk -d -o NAME,SIZE,MODEL
  ```
- List their permanent names (without the partitions):
  ```sh
  ls -l /dev/disk/by-id/ | grep -v part
  ```
- Every line ends with an arrow like `-> ../../nvme0n1`: that's the NAME
  from `lsblk`. Of the lines pointing to your disk, take the one that
  starts with `nvme-<model>_<serial>` (NVMe) or `ata-<model>_<serial>`
  (SATA). Ignore `nvme-eui…` and `wwn-…`, same disk, less readable.
- Store it in the variable `DISK`. Type the start and press **Tab**, the
  console completes the long name:
  ```sh
  DISK=/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T123456
  ```
- Check that it points to the right disk (the arrow at the end):
  ```sh
  ls -l $DISK
  ```
- Write it into `disko.nix`:
  ```sh
  sed -i "s|/dev/disk/by-id/CHANGE-ME|$DISK|" modules/hosts/$HOST/disko.nix
  ```
- Check:
  ```sh
  grep device modules/hosts/$HOST/disko.nix
  ```

> **In a virtual machine**, the virtual disk often has no by-id name. Use
> `DISK=/dev/vda` (or `/dev/sda`); a VM usually has only this one disk.
> Also switch on 3D acceleration in the VM settings, niri needs it.

## 5. Add yourself (the user)

**The idea:** a user is one file in `modules/users/`, published under the
user's name. The host lists that name (you did that with the second `sed`
in step 4). You copy slider's file, because it's already an admin: it's in
the group `wheel`, which allows `sudo`.

- Create your user file from slider's, with your name in every place:
  ```sh
  sed "s/slider/$NAME/g" modules/users/slider.nix > modules/users/$NAME.nix
  ```
- Look at it:
  ```sh
  cat modules/users/$NAME.nix
  ```

Your first password is **your user name** (`initialPassword`). You change
it right after the first start. `users/slider.nix` can stay: a user only
exists on hosts that list it.

### Optional: smaller first install (no gaming)

**The idea:** the host lists three bundles: `base` (every machine),
`desktop` (the graphical system and apps) and `gaming` (Steam, Lutris,
Prism Launcher, …). `gaming` is the biggest download. Leave it out now if
you like; adding the line back later and rebuilding installs it.

- Remove the `gaming` line from your host:
  ```sh
  sed -i '/^ *gaming$/d' modules/hosts/$HOST/$HOST.nix
  ```

### Optional: not German

**The idea:** flakeos speaks English, but uses a German keyboard, German
formats (date, numbers, paper size) and Berlin time. The keyboard is set
twice: for the text console (`system/locale.nix`) and for the desktop
(`programs/niri/config.kdl`, niri reads its own).

- Keyboard, e.g. `us` (others: `fr`, `es`, `it`, …):
  ```sh
  sed -i 's/"de"/"us"/' modules/system/locale.nix modules/programs/niri/config.kdl
  ```
  UK: the console calls it `uk`, niri calls it `gb`. Use `uk` here, then
  change niri's to `gb` in step 10.
- The list of time zones (q quits, / searches):
  ```sh
  timedatectl list-timezones
  ```
- Your time zone, e.g. New York:
  ```sh
  sed -i 's|Europe/Berlin|America/New_York|' modules/system/locale.nix
  ```
- The formats (`de_DE` lines) are easier to change after the install, in
  step 10.

## 6. Check the config

**The idea:** nothing on the disk has changed so far. Before erasing it,
let Nix read and check your whole config once. A typo shows up now, not
halfway through the install. The first time, this downloads the sources
(nixpkgs and friends), so it takes a few minutes.

- Tell git about the new files. The flake ignores files git doesn't know
  (skip this if you deleted `.git`):
  ```sh
  git add -A
  ```
- Check the config:
  ```sh
  nix --extra-experimental-features "nix-command flakes" eval .#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath
  ```
- **Good:** it prints one line ending in `-nixos-system-mybox-….drv`. A
  "Git tree is dirty" warning is normal.
- **Error:** the last lines name the file and line. Open the file with
  `nano <file>` (Ctrl+O saves, Ctrl+X quits), fix it, `git add -A`, run
  the check again.

## 7. Format the disk

**The idea:** disko takes the layout from `modules/setup/disko.nix`
(shared by all hosts) and the disk from your `disko.nix`:

```
ESP    1 GB   vfat   /boot   boot loader and kernels
root   rest   ext4   /       everything else
```

There's no swap partition; the system uses *zram* (compressed RAM) instead.
disko erases the disk, creates the two partitions, formats them and mounts
everything under `/mnt`.

**Everything on `$DISK` is gone after this.**

- Run disko:
  ```sh
  nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --flake .#$HOST
  ```
- It shows the disk it's about to wipe and asks. Type `yes`, then Enter.
- Check that the new root and `/mnt/boot` are mounted:
  ```sh
  findmnt -R /mnt
  ```

## 8. Install

**The idea:** `nixos-install` builds the system `.#$HOST` from the repo. It
downloads ready-built packages from cache.nixos.org, it compiles next to
nothing. Then it installs the boot loader. `--no-root-passwd` skips the root
password: root stays *locked*, and you do admin work with `sudo` and your
own password. One password less, and no one can log in as root.

- Install. This takes a while (several GB to download with `gaming`):
  ```sh
  nixos-install --flake .#$HOST --no-root-passwd
  ```
- It ends with `installation finished!`.
- Create your home folder on the new system:
  ```sh
  mkdir -p /mnt/home/$NAME
  ```
- Copy the repo there, with your new host and user in it:
  ```sh
  cp -r /tmp/flakeos /mnt/home/$NAME/flakeos
  ```
- The copy belongs to root. `nixos-enter` runs a command inside the new
  system, where your user exists, and gives your home folder to you:
  ```sh
  nixos-enter --root /mnt -c "chown -R $NAME:users /home/$NAME"
  ```
- Pull out the USB stick and restart:
  ```sh
  reboot
  ```

## 9. First start

**The idea:** after boot, greetd logs you straight into niri (automatic
login, no login screen) and noctalia draws the bar. If you log out, you
get a small text login screen instead.

- **Mod** is the Windows (Super) key. Open a terminal: **Mod+Return**.
- Change your password. It first asks for the current one, which is your
  user name:
  ```sh
  passwd
  ```
- Pick a wallpaper: **Mod+W**. Every login starts with a random one.
- All key binds: **Mod+BackSpace**. The most important ones, the commands
  and "where do I change what" are in the [main README](../../README.md).

## 10. Make it yours

**The idea:** a few settings in the repo are slider's personal ones. They
don't break anything, but you'll want your own. From now on you edit in
**Zed** (Mod+Z): it knows Nix, completes NixOS options and has a git panel.

- Open the repo in Zed:
  ```sh
  zeditor ~/flakeos
  ```
- Change these files (all in `modules/`):

  | file | change |
  |---|---|
  | `programs/git/gitconfig` | `name` and `email` under `[user]`: they go into every git commit you make |
  | `programs/zed/settings.json` | in the `lsp` part: `/home/slider/flakeos` → `/home/<you>/flakeos`, and `nixosConfigurations.zeus` → your hostname. Then Zed can complete NixOS options |
  | `programs/noctalia/settings.json` | `"location"` → `"name"`: your city (weather in the bar) |
  | `system/locale.nix` | the `LC_…` formats, e.g. `de_DE.UTF-8` → `en_GB.UTF-8` or `en_US.UTF-8` |
  | `programs/niri/config.kdl` | only if the desktop keyboard is still wrong: `layout "de"` (UK: `"gb"`) |

- Go to the repo in the terminal:
  ```sh
  cd ~/flakeos
  ```
- Tell git about the changes (skip without git):
  ```sh
  git add -A
  ```
- Rebuild the system with your changes:
  ```sh
  nrs
  ```

Also slider's, but only used on slider's machines: `hosts/zeus/`,
`hosts/hermes/`, `users/slider.nix` and `programs/openrgb/` (only zeus
lists it). Keep them as examples or delete them; if you delete the two
host folders, the other two can go as well.

---

## Optional: your own GitHub repo

**The idea:** your `~/flakeos` is a copy of slider's GitHub repo, and
`git push` would try to upload to slider's (and fail, no permission). To
keep your config on GitHub, as a backup or to share it between your PCs,
point it to a repo of your own.

GitHub only accepts uploads with a key. An *SSH key* is a pair of files:
the private half (`~/.ssh/id_ed25519`) never leaves your PC, the public
half (`id_ed25519.pub`) goes to GitHub. flakeos is already prepared:
`programs/git/gitconfig` sends every push to GitHub over SSH, and
`programs/git/git.nix` already trusts GitHub's server. So after this, the
git panel in Zed can push too.

Do step 10 first, so your commits carry your own name.

- On github.com: **New repository**, name it e.g. `flakeos`, and leave it
  empty (no README, no licence).
- Make a key. Press Enter at every question (default place, no passphrase):
  ```sh
  ssh-keygen -t ed25519 -C "you@example.com"
  ```
- Show the public half:
  ```sh
  cat ~/.ssh/id_ed25519.pub
  ```
- Copy the whole line. On GitHub: your picture → **Settings** → **SSH and
  GPG keys** → **New SSH key**, give it a name (e.g. your hostname), paste,
  **Add SSH key**.
- Test the key. The answer should be "Hi <you>! You've successfully
  authenticated":
  ```sh
  ssh -T git@github.com
  ```
- Go to the repo:
  ```sh
  cd ~/flakeos
  ```
- Point it to your repo (put in your GitHub name):
  ```sh
  git remote set-url origin https://github.com/YOUR-NAME/flakeos.git
  ```
- Mark everything for the first commit:
  ```sh
  git add -A
  ```
- Save it as a commit:
  ```sh
  git commit -m "my flakeos"
  ```
- Upload it. `-u` remembers the target, so later a plain `git push` is enough:
  ```sh
  git push -u origin main
  ```

From now on: "Saving changes to GitHub" in the
[main README](../../README.md#saving-changes-to-github).

Never share `~/.ssh/id_ed25519` (the one without `.pub`), and never put it
into the repo. If it's public, anyone can push as you.

## Reinstalling a configured host (example: zeus)

The short version, for a machine whose host (`hardware.nix`, `disko.nix`)
and user are already in the repo on GitHub. Nothing to create, so steps 3
to 6 fall away. For another configured host, replace `zeus` (and `slider`,
if it's another user).

1. **Back up, on the old system.** The install erases the 1 TB system drive,
   where `/home/slider` lives. The 2 TB data drive (`/mnt/data`) is never
   touched. Push your latest changes to GitHub, then copy the SSH key to
   the data drive:
   ```sh
   cp -r ~/.ssh /mnt/data/ssh-backup
   ```

2. **Boot the installer** (see [step 1](#1-boot-the-installer)), become root:
   ```sh
   sudo -i
   ```
   German keyboard:
   ```sh
   loadkeys de
   ```
   Wi-Fi only (cable works by itself):
   ```sh
   nmtui
   ```

3. **Get the repo:**
   ```sh
   git clone https://github.com/slider104/flakeos.git /tmp/flakeos
   ```
   ```sh
   cd /tmp/flakeos
   ```

4. **Check the disk.** The disk in `disko.nix` must show up in the list:
   ```sh
   grep device modules/hosts/zeus/disko.nix
   ```
   ```sh
   ls -l /dev/disk/by-id/ | grep -v part
   ```

5. **Format** (**erases that disk**; type `yes` when asked):
   ```sh
   nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --flake .#zeus
   ```

6. **Install, then restart** (pull out the USB stick):
   ```sh
   nixos-install --flake .#zeus --no-root-passwd
   ```
   ```sh
   reboot
   ```

7. **First start.** You're logged into niri automatically. Open a terminal
   (Mod+Return), change the password (the first one is `slider`):
   ```sh
   passwd
   ```
   Get the repo into your home:
   ```sh
   git clone https://github.com/slider104/flakeos.git ~/flakeos
   ```

8. **Put the SSH key back**, readable only for you (ssh refuses it
   otherwise):
   ```sh
   cp -r /mnt/data/ssh-backup ~/.ssh
   ```
   ```sh
   chmod 700 ~/.ssh
   ```
   ```sh
   chmod 600 ~/.ssh/id_ed25519
   ```
   Check, it should answer "Hi slider104!":
   ```sh
   ssh -T git@github.com
   ```

Then press Mod+W for a wallpaper. Done.

---

## When something goes wrong

- **disko says the disk doesn't exist:** `$DISK` has a typo, or
  `disko.nix` still says `CHANGE-ME`. Redo [Which disk](#which-disk).
- **`nixos-install` stops halfway** (network gone): run it again, it picks
  up where it stopped. The disk is still mounted.
- **You rebooted in the middle of the install:** `/tmp` was in RAM, so the
  repo is gone. Redo steps 1 to 6, then mount the disk *without* erasing
  it, and go on with step 8:
  ```sh
  nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount --flake .#$HOST
  ```
- **After the reboot the PC doesn't boot flakeos:** in the PC's boot menu
  (F12, …) pick "Linux Boot Manager", and make it the first entry in the
  firmware settings. UEFI must be on, "legacy/CSM" boot off.
- **The desktop doesn't start** (black screen or back at a text login):
  log in there and look at what went wrong:
  ```sh
  journalctl -b -u greetd
  ```
- **Forgot your password:** "Locked out?" in the
  [main README](../../README.md#something-broke).

---

## What else is in this folder

Nothing here is day-to-day; it's how the flake is wired together.

| file | what it does |
|---|---|
| `disko.nix` | the disk layout above (ESP + ext4 root), shared by all hosts. Each host's `disko.nix` only adds which disk |
| `parts.nix` | loads the wrapper library (`flake.wrappers.<name>`), makes listing a module twice harmless, adds `flake.lib` for helpers like `mkDisko`, and sets up `nix fmt` |
| `README.md` | this guide |
