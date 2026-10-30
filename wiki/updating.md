# Updating

**How it works:** `flake.lock` pins the exact version of nixpkgs (which means
every program) and of the other inputs. **Nothing updates by itself** â not
the kernel, not Firefox, not anything. You decide when, by running `nup`,
which moves the pins to the newest versions and builds the new system for the
next boot.

A machine you don't touch for three months is the same machine when you come
back. That is a feature, and it also means the update is a thing you do
deliberately, with a plan. This page is the plan.

## Contents

- [The normal update](#the-normal-update)
- [How risky is an update?](#how-risky-is-an-update)
  - [The four things that can happen](#the-four-things-that-can-happen)
  - [The three ways back](#the-three-ways-back)
  - [Where the risk actually sits](#where-the-risk-actually-sits)
  - [Habits that make it cheaper](#habits-that-make-it-cheaper)
- [When a package doesn't build](#when-a-package-doesnt-build)
- [Updating two machines](#updating-two-machines)
- [Twice a year: a new NixOS release](#twice-a-year-a-new-nixos-release)
- [Updating one input only](#updating-one-input-only)

---

## The normal update

- Update and build:
  ```sh
  nup
  ```
- Reboot to use it:
  ```sh
  reboot
  ```
- Spend two minutes trying the things you care about: the bar, sound, Wi-Fi, a
  game.

That's it. What `nup` does under the hood, and why it is safe:

- It runs `nix flake update` (moving the pins), then
  `nixos-rebuild boot` â which builds **everything** first and only touches
  the boot menu once that worked. So an update that doesn't build cannot
  damage the running system.
- **If the build fails it puts `flake.lock` back.** A failed `nup` leaves you
  exactly where you started, with nothing to undo by hand. (Had you already
  changed `flake.lock` yourself, it is left alone and says so.)
- A successful `nup` ends with a list of **what actually changes at the next
  boot**: package names with their old and new versions, and how much the
  system grows or shrinks. Worth reading â it is the best "how big is this
  update" signal there is.
- The whole output is also saved to `~/flakeos/logs/update_<date>.log`.

It builds for the **next boot** on purpose, not for right now. A kernel update
mid-session is not something you want, and a reboot is the cleanest way into a
new system.

---

## How risky is an update?

**The idea:** an update can cost you *time*, never the machine. The new system
is built completely before anything switches over, and the old one stays in
the boot menu afterwards. So every way an update can go wrong has a way back
that needs no Nix knowledge at all.

### The four things that can happen

Commonest first:

1. **The build fails.** The harmless one: nothing changed, `nup` put
   `flake.lock` back, you are on the same system as before. Usually not your
   config â unstable had a bad day. See
   [When a package doesn't build](#when-a-package-doesnt-build).
2. **It builds, but something behaves differently afterwards.** Reboot and
   pick an older generation in the boot menu.
3. **A NixOS option was renamed.** The rebuild stops and the message names the
   old option, usually together with the new one. A few times a year, mostly
   around the releases in May and November. Mechanical to fix.
4. **A program changed its config format.** The rare one, and the only one
   that is real work: the new version ignores what we wrote for the old one,
   so those settings have to be written again. noctalia 4 â 5 in October 2026
   was this.

### The three ways back

None of these need you to understand the error.

**Case 1 â you never left the old system.** Nothing to do. The last lines of
`~/flakeos/logs/update_<date>.log` say what broke, and `git diff flake.lock`
shows what would have moved.

**Case 2 â back to the old system.** Reboot and pick an older generation in
the boot menu (shown for 5 seconds; any arrow key stops the countdown). To see
beforehand what those entries are:

```sh
nixos-rebuild list-generations
```

**Cases 2 to 4 â back to the old *versions*,** so the next rebuild stops
bringing the new ones:

```sh
cd ~/flakeos
```
```sh
git checkout flake.lock
```
```sh
nrs
```

That last one is the important one to internalise. `flake.lock` is a normal
file in git. Throwing away your changes to it puts every program in the system
back to the versions that were working an hour ago. It is a complete,
one-command undo of an entire update.

### Where the risk actually sits

Cases 3 and 4 need a *program* to change something, so the only real question
is which of ours change often.

- **noctalia is the one to watch.** A young project that still changes shape,
  and the only program here that is *hand*-wrapped â no module in
  nix-wrapper-modules absorbs its changes for us, so
  `modules/programs/noctalia/noctalia.nix` is ours to fix. Its config is
  checked while the system is built (`noctalia config validate`), so a key
  that no longer exists fails the rebuild instead of leaving you with a bar
  that won't start. That is the good kind of failure: loud, early, and before
  anything switched.
- **niri** and **nix-wrapper-modules** are young too, but with small option
  surfaces: changes are few and named in their release notes.
- **Everything else** â alacritty, zsh, mpv, Steam, PipeWire, systemd-boot,
  zram, disko â has a settled config format. These effectively never need work
  after an update.

### Habits that make it cheaper

- **Update when you have a free hour**, not on the evening you need the
  machine.
- **After the reboot, spend two minutes** trying the bar, sound, Wi-Fi, a game.
  Noticing a problem while you still remember that you updated is half the
  work.
- **Update regularly rather than rarely.** In small steps `nup`'s version list
  points straight at the suspect; after half a year everything moved at once
  and you have no idea which change did it.
- **Update zeus first and let hermes follow a few days later** (`git pull`), so
  the laptop is never the one that finds the problem.
- **Keep the NixOS installer stick in a drawer.** The one thing that cannot be
  repaired from inside the system is a forgotten password â see
  [troubleshoot.md](troubleshoot.md#locked-out).
- **Commit before you update.** Then `git diff` afterwards is a clean picture
  of exactly what the update moved.

---

## When a package doesn't build

Unstable moves fast, so now and then a package there is broken for a few days
â and it can easily be one you never asked for. In October 2026 `breakpad`
stopped compiling; noctalia depends on it, so *nothing* built at all.

You don't have to freeze the whole system for that.
`modules/system/stable.nix` keeps a second, slower-moving nixpkgs around (the
latest NixOS release, pinned as `nixpkgs-stable` in `flake.nix`). Nothing uses
it until you say so, in one of two ways.

**One program from stable**, nothing else touched. `pkgs.stable` works like
`pkgs` in any module:

```nix
environment.systemPackages = [pkgs.stable.inkscape];
```

**One package replaced everywhere**, including inside other packages that need
it â the breakpad case. Uncomment a line in `modules/system/stable.nix`:

```nix
breakpad = final.stable.breakpad; # 2026-10-04: link error, nixpkgs#569271
```

Write next to the line **what broke and when**, and delete it again once
unstable is fixed. These lines are meant to be temporary; the file itself
explains both ways and what they cost.

### The trap, learned the hard way

One warning for programs that draw on screen: a borrowed package brings its
own libraries, but the **graphics driver always comes from the running
system**. If the two nixpkgs are far apart, the driver can't load into that
program and it starts up showing nothing at all ("EGL not available" in its
log, if you're lucky).

For anything graphical, point `nixpkgs-stable` in `flake.nix` at an **unstable
commit from just before the breakage** instead of at the release branch:

```nix
nixpkgs-stable.url = "github:nixos/nixpkgs/<commit-hash>";
```

Command-line tools and services are not affected. `modules/system/stable.nix`
has the full story in its comments.

### How to tell whether it's you or unstable

```sh
nck
```

If the config evaluates fine and the failure is `builder for '/nix/store/â¦'
failed`, it is a package build, not your config. The package name is in the
store path. Then:

- Search it on https://github.com/NixOS/nixpkgs/issues â a package broken for
  everyone usually has an issue open within hours.
- Or just wait a day and run `nup` again. Most of these fix themselves.
- Or `git checkout flake.lock` and get on with your life.

---

## Updating two machines

Run `nup` on **one** machine only, then commit and push `flake.lock`. The
other machine pulls and runs `nrs`, and gets exactly the same versions.

```sh
cd ~/flakeos
```
```sh
git add flake.lock && git commit -m "update" && git push
```

Then on the other machine:

```sh
git pull
```
```sh
nrs
```

Ran `nup` on both and now `flake.lock` conflicts? Keep the one from GitHub,
then `nrs` so this machine builds those versions instead of its own discarded
update:

```sh
git checkout --ours flake.lock
```
```sh
git add flake.lock
```
```sh
git rebase --continue
```
```sh
nrs
```

(In a rebase, `--ours` is the GitHub side. Yes, that is backwards from what it
sounds like.) More on two machines: [git.md](git.md).

---

## Twice a year: a new NixOS release

NixOS releases in May and November (`nixos-26.05`, `nixos-26.11`, â¦). This
system follows **unstable**, so a release is not an event for you â you are
already running newer than it.

The one thing to do: point `nixpkgs-stable` in `flake.nix` at the new release.

```nix
nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.11";
```

Nothing depends on it day to day, but the escape hatch above only works while
the two nixpkgs are reasonably close together.

**Do not change `system.stateVersion`** in the host files. It is not a version
to keep current â it records how old the machine's *data* is, so NixOS knows
which migrations it needs. Leave it at whatever it was when the machine was
installed, forever.

## Updating one input only

`nup` updates everything. To move just one pin — say the wrapper machinery,
without pulling in a new nixpkgs:

```sh
cd ~/flakeos
```
```sh
nix flake update wrapper-modules
```
```sh
nrb
```

What the inputs are:

```sh
nix flake metadata
```

| input | what it is |
|---|---|
| `nixpkgs` | nixos-unstable: every program in the system |
| `nixpkgs-stable` | the escape hatch above. Only used if a line in `stable.nix` says so |
| `flake-parts`, `import-tree` | how the flake is structured |
| `wrapper-modules` | the wrapping machinery |
| `disko` | partitioning, only used when installing a machine |

Updating a single input is handy for bisecting: if an update broke something
and you have no idea what, `git checkout flake.lock`, then move the inputs one
at a time until it breaks again.
