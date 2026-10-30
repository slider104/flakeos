# Troubleshooting: logs, services and the ways back

The page to open when something is broken. It starts with the two questions
that decide everything, then the logs, then a symptom list.

**The thing to hold on to:** a rebuild either works or it doesn't. It never
half-happens. The old system is still on the disk and still in the boot menu.
Nothing on this page can cost you more than a reboot and some reading.

## Contents

- [Start here: two questions](#start-here-two-questions)
- [Reading a failed rebuild](#reading-a-failed-rebuild)
- [journalctl: the system log](#journalctl-the-system-log)
- [systemctl: services](#systemctl-services)
- [Going back: generations](#going-back-generations)
- [Symptom list](#symptom-list)
  - [The desktop doesn't start](#the-desktop-doesnt-start)
  - [The bar is missing](#the-bar-is-missing)
  - [A change doesn't show up](#a-change-doesnt-show-up)
  - [No sound](#no-sound)
  - [No network](#no-network)
  - [A program won't start](#a-program-wont-start)
  - [A game or program is slow or won't display](#a-game-or-program-is-slow-or-wont-display)
  - [The disk is full](#the-disk-is-full)
  - [The keyboard is dead after a reboot](#the-keyboard-is-dead-after-a-reboot)
  - [Something hardware-specific](#something-hardware-specific)
- [Locked out](#locked-out)
- [The machine won't boot at all](#the-machine-wont-boot-at-all)
- [The nuclear option](#the-nuclear-option)
- [Cheat sheet](#cheat-sheet)

---

## Start here: two questions

**1. Did the rebuild fail, or did it succeed?**

| | |
|---|---|
| **It failed** (red error, no "switching to configuration") | **Nothing changed.** You are on the same system you were on before. Go to [Reading a failed rebuild](#reading-a-failed-rebuild) |
| **It worked, and now something is wrong** | The new system is live. Go to [Going back: generations](#going-back-generations) to get out, then fix the file |

**2. Did you just update?**

If `nup` is anywhere near this problem, read
[updating.md](updating.md#how-risky-is-an-update) instead. It sorts the four
things an update can do and gives the way out of each one.

---

## Reading a failed rebuild

A failed rebuild has done nothing to your machine. Take your time.

- **The error is in the last lines**, not the first. Scroll up only as far as
  the first line that names a *file*.
- **The whole output is saved**, so nothing scrolls away for good. The last
  line a rebuild prints is the path of its own log:
  ```sh
  ll ~/flakeos/logs
  ```
  ```sh
  bat ~/flakeos/logs/rebuild_2026-10-30-14:03:22.log
  ```
- Only want the error lines out of a long log?
  ```sh
  grep -i "error\|cannot\|undefined" ~/flakeos/logs/rebuild_2026-10-30-14:03:22.log
  ```

### What the common errors mean

| the error says | it usually means |
|---|---|
| `undefined variable 'pinta'`, pointing at a list | something lists a name that nothing publishes: a typo, **or the new file isn't `git add`ed** |
| `undefined variable 'pkgs'` (or `lib`) | the module's first line needs it: `{pkgs, ...}: {` or `{pkgs, lib, ...}: {` |
| ``The option `programs.pinta' does not exist`` | wrong option name, or NixOS has no module for that program — use `environment.systemPackages` |
| `syntax error, unexpected …` | a missing `;`, `}` or `"`, just *before* the line it names |
| `option … is already declared` | the same program is wrapped in two files |
| `The option `services.foo.bar' has been renamed to …` | NixOS renamed an option. The message names the new one. Happens a few times a year |
| `error: builder for '/nix/store/…' failed` | a *package* failed to compile. Usually not your doing — see [When a package doesn't build](updating.md#when-a-package-doesnt-build) |
| `Git tree is dirty` | **not an error.** It only means you have uncommitted changes |

### Check without building

`ndb` reads the whole config for this machine and stops before it builds
anything, so a typo shows up in seconds and no password is needed:

```sh
ndb
```

`nck` is the wider question — it checks every host and every module, so it
also catches breaking the other machine:

```sh
nck
```

Neither can catch an error that only appears while a package is *compiling*.

---

## journalctl: the system log

Everything the system and its services print lands in one journal. This is
*the* tool. The flags are worth learning, because they are the difference
between one useful screen and forty thousand lines.

All of these page with **less**: arrows scroll, `/word` searches, **q** quits.
`-e` jumps straight to the end, which is usually where you want to be.

| command | shows |
|---|---|
| `journalctl -b -e` | everything since **this boot**, jumped to the end |
| `journalctl -b -p err` | only errors since this boot. **The best first look** |
| `journalctl -b -1 -e` | everything from the **previous** boot — what you read after a crash or freeze |
| `journalctl -u <service> -b` | one service only, e.g. `journalctl -u greetd -b` |
| `journalctl -f` | follow live: new lines appear as they happen. Ctrl+C stops |
| `journalctl -u <service> -f` | follow one service live, e.g. while you reproduce the problem |
| `journalctl -k -b` | the **kernel's** own messages (hardware, drivers, USB) |
| `journalctl --user -b -e` | your *session's* services, not the system's. Where niri and noctalia end up |
| `journalctl --since "10 min ago"` | by time. Also `--since today`, `--since "2026-10-30 14:00"` |
| `journalctl -g <word> -b` | only lines matching a word (`-g` = grep) |
| `journalctl --disk-usage` | how much space the journal is using |

Two that answer "why did niri/the bar do that":

```sh
journalctl --user -u niri -b -e
```
```sh
journalctl --user -b -g noctalia -e
```

Combine freely: `journalctl -u libvirtd -b -p err` is "errors from libvirt
this boot".

### A quirk worth knowing

niri and noctalia are started by your *session*, so they log to the
**`--user`** journal, not the system one. Forgetting `--user` is the most
common reason someone concludes "there's nothing in the log".

---

## systemctl: services

A *service* is a background program the system starts: the sound server, the
network manager, the login screen, libvirt.

| command | does |
|---|---|
| `systemctl status <name>` | is it running? Plus its last log lines (**q** quits) |
| `sudo systemctl restart <name>` | restart it |
| `sudo systemctl stop <name>` | stop it until the next boot |
| `systemctl list-units --failed` | **everything that failed to start.** A good thing to run when the machine feels off |
| `systemctl --user status <name>` | the same for your session's services |
| `systemctl --user list-units --failed` | failed session services |
| `systemd-analyze blame` | what made this boot slow |

The services in this config worth knowing by name:

| service | what it does | page |
|---|---|---|
| `greetd` | the login / autologin that starts niri | [the desktop doesn't start](#the-desktop-doesnt-start) |
| `NetworkManager` | Wi-Fi and ethernet | [no network](#no-network) |
| `libvirtd` | virtual machines | [virtualisation.md](virtualisation.md) |
| `libvirt-default-network` | the VM's NAT switch | [virtualisation.md](virtualisation.md) |
| `openrgb`, `openrgb-colour` | the RGB lighting (zeus) | [hardware.md](hardware.md#rgb-lighting-zeus) |
| `keyd` | the Corsair mouse's side buttons (zeus) | [hardware.md](hardware.md#the-corsair-mouse-zeus) |
| `ydotoold` | the autoclicker's fake mouse | [hardware.md](hardware.md#the-autoclicker) |
| `usb-rescue` | repairs USB ports that came up dead | [keyboard dead after a reboot](#the-keyboard-is-dead-after-a-reboot) |
| `nix-gc`, `nix-optimise` | the weekly cleanups | [the disk is full](#the-disk-is-full) |

Restarting a service does **not** need a rebuild, and it does not change your
config — at the next boot you are back to what the repo says.

**Note:** `systemctl edit` and friends do nothing useful here. Service
definitions come from the repo; change the module and `nrs`.

---

## Going back: generations

Every rebuild leaves the previous system intact. This is the way out of
anything.

- **See what you can go back to:**
  ```sh
  nixos-rebuild list-generations
  ```
  The one marked `current` is what you are running.
- **The reliable way back: reboot.** The boot menu appears for 5 seconds —
  press any arrow key to stop the countdown, then pick an older entry. That
  works even when the desktop is completely dead, because it happens before
  the system starts.
- **Without rebooting**, if you are only one bad rebuild deep:
  ```sh
  sudo nixos-rebuild switch --rollback
  ```
  This switches to the previous generation. Services restart; a kernel change
  still needs a reboot to take effect.
- **Then fix the file** and `nrs` again. Booting an old generation does not
  change `~/flakeos` — your edit is still there, waiting.

Two things that are **not** in a generation, so rolling back does not bring
them back:

- your **home folder** (documents, Firefox profile, Steam games)
- your **password**

Which is why [Locked out](#locked-out) is its own section.

---

## Symptom list

### The desktop doesn't start

Black screen, or you land on a text login prompt.

- Log in there (your user name and password) and ask what happened:
  ```sh
  journalctl -u greetd -b -e
  ```
- And the session's own side:
  ```sh
  journalctl --user -b -e
  ```
- No graphics at all? Check the driver loaded:
  ```sh
  journalctl -k -b | grep -i "drm\|amdgpu\|nvidia\|i915"
  ```
- Can't fix it from there: **reboot and pick the previous generation**. Then
  fix the file with `fresh ~/flakeos/...` or `nano`, and `nrs`.
- Switch between text consoles with **Ctrl+Alt+F1 … F6** — handy when the
  graphical session is wedged but the machine is alive.

### The bar is missing

noctalia is not running, or it crashed.

- Start it and watch what it says:
  ```sh
  noctalia -d
  ```
- Restart it properly:
  ```sh
  pkill -f 'bin/noctalia$'
  ```
  ```sh
  niri msg action spawn -- noctalia
  ```
- Note `pkill -x noctalia` finds nothing: the wrapper runs a binary called
  `.noctalia-wrapped`.
- Full details, including why a rebuild alone does not reach a running
  noctalia: [noctalia.md](noctalia.md).

### A change doesn't show up

The rebuild said it worked, but nothing is different. Almost always one of
these three:

1. **The file is new and you didn't `git add` it.** The flake only sees files
   git knows about, and a missing file is silent — no error.
   ```sh
   cd ~/flakeos
   ```
   ```sh
   git status
   ```
   Files listed as `Untracked` are invisible to the build.
   ```sh
   git add -A
   ```
   ```sh
   nrs
   ```
2. **The program was already open.** A wrapped program reads its config when
   it starts. Close and reopen it. For the bar, see
   [the bar is missing](#the-bar-is-missing).
3. **Nothing *lists* your new module.** Publishing a module does nothing; a
   bundle in `modules/grouped/` or a host in `modules/hosts/` has to name it.
   See [blueprints.md](blueprints.md#how-a-module-becomes-part-of-the-system).
   ```sh
   grep -rnw pinta modules
   ```

A fourth, rarer one: you edited `~/.config/<program>` for a program that is
**wrapped**, where that folder is never read. See
[settings.md](settings.md).

### No sound

- What does PipeWire see?
  ```sh
  wpctl status
  ```
  Sinks are outputs, sources are inputs. The one with a `*` is the default.
- Volume and mute of the default output:
  ```sh
  wpctl get-volume @DEFAULT_AUDIO_SINK@
  ```
  ```sh
  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
  ```
- Wrong device? noctalia's control center has an output picker, or:
  ```sh
  wpctl set-default <ID>
  ```
  (the ID is the number at the start of the line in `wpctl status`.)
- Restart the sound server — this is per-user, so **no sudo**:
  ```sh
  systemctl --user restart pipewire pipewire-pulse wireplumber
  ```
- Still nothing? Does the kernel even see the card?
  ```sh
  journalctl -k -b | grep -i "snd\|audio"
  ```
- More on audio, including the microphone: [hardware.md](hardware.md#sound).

### No network

- Is the service up?
  ```sh
  systemctl status NetworkManager
  ```
- What does it think it has?
  ```sh
  nmcli device status
  ```
  ```sh
  nmcli connection show
  ```
- Wi-Fi from a terminal, with a menu (works on the text console too):
  ```sh
  nmtui
  ```
- Is it the network or the name lookup?
  ```sh
  ping -c 3 1.1.1.1
  ```
  ```sh
  ping -c 3 nixos.org
  ```
  First works, second doesn't → DNS. Both fail → no connection.
- The firewall is on (`modules/system/network.nix`). Something can't be
  reached *from another machine*? That is usually a closed port, not a bug:
  ```sh
  sudo iptables -L -n | head -40
  ```

### A program won't start

- **Run it from a terminal.** A program started from the launcher throws its
  error away; started from a terminal, it tells you:
  ```sh
  thunar
  ```
- A *wrapped* program, straight out of the repo, with its config:
  ```sh
  cd ~/flakeos
  ```
  ```sh
  nix run .#alacritty
  ```
- Something you downloaded (`cannot execute: required file not found`): see
  [Running a program you downloaded](general.md#running-a-program-you-downloaded).
- A program that used to work and stopped right after an update:
  [updating.md](updating.md).

### A game or program is slow or won't display

- Is the graphics driver healthy?
  ```sh
  vulkaninfo --summary
  ```
  It should name your card. If it says `llvmpipe`, the driver did not load and
  the CPU is drawing everything — correct picture, terrible speed.
- Is it using the real GPU? Turn on the overlay and look:
  ```sh
  mangohud <program>
  ```
- Everything about Steam, Proton, GameMode, gamescope and launch options is
  in [gaming.md](gaming.md).

### The disk is full

```sh
df -h
```

Nix stores every version of everything, so this is the one maintenance job
the system has.

- Delete generations older than 30 days (this is what `ncg` does):
  ```sh
  ncg
  ```
- Harsher: keep only the current system. **You lose your rollback entries**,
  so don't do this right after an update:
  ```sh
  sudo nix-collect-garbage -d
  ```
- The boot menu entries disappear at the next `nrs`, not immediately.
- What is actually big in your home folder?
  ```sh
  du -sh ~/* | sort -h
  ```
- Candidates that are not the Nix store: `~/flakeos/logs`, Steam's library,
  `/var/lib/libvirt/images` (VM disks), the journal:
  ```sh
  journalctl --disk-usage
  ```
  ```sh
  sudo journalctl --vacuum-time=14d
  ```
- A weekly job already does the `ncg` part, plus a nightly job that
  de-duplicates the store (`modules/system/nix.nix`). On a normal week you
  never have to think about this.

### The keyboard is dead after a reboot

A known quirk of zeus' USB hub, and it is already handled — but here is what
is going on, in case it ever comes back.

On a warm reboot the board keeps power on the hub port, so the keyboard's own
chip never restarts and the kernel can't talk to it. A real power-off fixes
it; so does unplugging and replugging.

`modules/system/reboot.nix` does two things about it: it cuts power to every
keyboard port on the way down, and after boot it power-cycles any port the
kernel gave up on.

- Did a port fail this boot?
  ```sh
  journalctl -k -b | grep "unable to enumerate"
  ```
- Did the rescue run?
  ```sh
  systemctl status usb-rescue
  ```
- Is the shutdown hook in place?
  ```sh
  ls -l /etc/systemd/system-shutdown/
  ```

### Something hardware-specific

Sound, Bluetooth, monitors, the graphics card, the RGB lighting, the Corsair
mouse's side buttons, the autoclicker and the data drive all have their own
section in [hardware.md](hardware.md).

---

## Locked out

Passwords and your home folder are **not** part of a generation, so this is
the one category a rollback cannot fix. Both cases have a way out.

### sudo stopped working after a rebuild

Reboot and pick an older generation in the boot menu. Your user's groups
(including `wheel`, which gives you sudo) come from the system, so an older
generation gives them back.

### You forgot your password

The only thing on this machine that cannot be repaired from inside it. You
need the NixOS installer USB stick — **keep one in a drawer.** Writing one
takes five minutes with `mediawriter` (it's in the launcher) and the Minimal
ISO from https://nixos.org/download/.

- Boot the stick, take the first menu entry.
- Mount your root partition:
  ```sh
  sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
  ```
- Step into your installed system and set a new password:
  ```sh
  sudo nixos-enter --root /mnt -c 'passwd <your user name>'
  ```
- Restart, pull the stick out:
  ```sh
  reboot
  ```

That is the whole procedure. It works because `nixos-enter` runs a command
*inside* your system, where your user exists, without needing to log in.

---

## The machine won't boot at all

Working from the outside in:

1. **No boot menu, straight to the firmware or "no bootable device".** In the
   PC's own boot menu (F12, F11, F8 or Esc, depends on the board) pick
   **Linux Boot Manager**, and make it the first entry in the firmware
   settings. UEFI must be on, "legacy/CSM" boot off.
2. **Boot menu appears, but every entry fails.** Press `e` on an entry to see
   its kernel line. Then boot the installer USB stick and read the installed
   system's last log:
   ```sh
   sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
   ```
   ```sh
   sudo journalctl -D /mnt/var/log/journal -b -1 -e
   ```
3. **It boots but hangs before the desktop.** Pick an older generation. Then
   [the desktop doesn't start](#the-desktop-doesnt-start).
4. **You need to fix a file but can't get a desktop.** Any text console
   (Ctrl+Alt+F2) has `fresh` and `nano`:
   ```sh
   nano ~/flakeos/modules/system/boot.nix
   ```
   ```sh
   cd ~/flakeos && git add -A && nrs
   ```
5. **You need to fix a file and can't even log in.** Boot the installer stick
   and work in your system from there:
   ```sh
   sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
   ```
   ```sh
   sudo nixos-enter --root /mnt
   ```
   You are now root inside your own system, with the repo still at
   `/home/<your user name>/flakeos` exactly as you left it. `nano`, fix,
   `nixos-rebuild switch --flake /home/<your user name>/flakeos`, `exit`,
   `reboot`.

Step 5 is the real floor of this system. As long as the disk spins and you
have a USB stick, your config is reachable and buildable.

---

## The nuclear option

It is worth knowing that a reinstall is not a disaster here, because the
machine *is* the repo. Push your changes to GitHub, boot the installer, and
[install.md](install.md#reinstalling-a-configured-host-example-zeus) puts
zeus back exactly as it was in about an hour — same programs, same keys, same
colours. On zeus, `/mnt/data` is never touched by the install.

What you would lose: anything in your home folder that is not in the repo or
on the data drive. Which is a decent argument for keeping the things you care
about on the data drive, or in git.

---

## Cheat sheet

```sh
# did it fail, and why
ll ~/flakeos/logs
journalctl -b -p err              # errors this boot
journalctl -b -1 -e               # the boot before this one
systemctl list-units --failed     # anything that didn't start
systemctl --user list-units --failed

# one thing at a time
systemctl status greetd
journalctl -u greetd -b -e
journalctl --user -u niri -b -e   # niri and noctalia need --user
journalctl -k -b                  # the kernel: hardware, USB, drivers
journalctl -f                     # live

# check the config without building
ndb                               # this machine
nck                               # every host and module

# get out
nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback
#   or: reboot and pick an older entry in the boot menu

# space
df -h
ncg
du -sh ~/* | sort -h
```
