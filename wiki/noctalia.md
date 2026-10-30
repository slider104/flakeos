# noctalia: the bar, launcher and notifications

noctalia is the shell around niri: the bar at the top, the app launcher, the
notification popups, the control center, the lock screen, the wallpaper
picker and the volume/brightness on-screen displays. niri starts it with the
session.

It is also **the one program in this config whose settings you are expected
to change in a GUI**, which makes it a special case. The second half of this
page is about getting those changes into the repo so they survive a reinstall.

## Contents

- [What it gives you](#what-it-gives-you)
- [The keys](#the-keys)
- [Wallpapers](#wallpapers)
- [Restarting it](#restarting-it)
- [Keeping what you changed](#keeping-what-you-changed)
  - [How it works](#how-it-works)
  - [The procedure](#the-procedure)
  - [Why the last step matters](#why-the-last-step-matters)
  - [Good to know](#good-to-know)
- [Editing config.toml by hand](#editing-configtoml-by-hand)
- [When it breaks](#when-it-breaks)

---

## What it gives you

| part | where |
|---|---|
| **The bar** | top of the screen. Workspaces, clock, system monitor, tray, battery, the NixOS logo as the launcher button |
| **The launcher** | Mod+Space. Type a few letters, Enter. Also does calculations and a few other tricks |
| **The control center** | click the right end of the bar, or Mod+N. Wi-Fi, Bluetooth, audio devices, power profiles, brightness, notification history |
| **Notifications** | popups top-right, with a history you can go back to |
| **The session menu** | Mod+Alt+L. Lock, suspend, reboot, power off |
| **The lock screen** | Mod+Alt+L → Lock |
| **The wallpaper picker** | Mod+W |
| **The OSD** | the little overlay when you change volume or brightness |
| **The settings window** | Mod+Comma |

The weather in the control center uses the city in `[location]` →
`address` in `modules/programs/noctalia/config.toml`.

## The keys

| key | does |
|---|---|
| Mod+Space | launcher |
| Mod+N | notification history (control center) |
| Mod+Shift+N | dismiss the popups on screen now |
| Mod+Ctrl+N | empty the history |
| Mod+W | pick a wallpaper |
| Mod+Comma | the settings window |
| Mod+Alt+L | session menu |

Everything noctalia does is also reachable from the command line, which is
how the key binds in `config.kdl` call it:

```sh
noctalia msg panel-toggle launcher
```
```sh
noctalia msg --help
```

## Wallpapers

The images in `~/flakeos/wallpapers/` (repo root, **not** inside `modules/`)
are installed to `/etc/wallpapers`. Mod+W picks one, and noctalia remembers
it, so it survives logins and reboots.

To add one:

- Put the file in `~/flakeos/wallpapers/`.
- Tell git, so the flake sees it:
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git add -A
  ```
- Rebuild:
  ```sh
  nrs
  ```
- Press **Mod+W** and pick it.

Want it to change on its own instead? Add a section to
`modules/programs/noctalia/config.toml`:

```toml
[wallpaper.automation]
enabled = true
interval_seconds = 1800
order = "random"
```

The chosen wallpaper is deliberately kept *out* of the repo — see
[Good to know](#good-to-know).

## Restarting it

This is the one thing about noctalia you have to know, because it is not
obvious: **a rebuild does not reach a running noctalia.**

The reason is how the wrapper works. noctalia is told where its config is
through an environment variable pointing into the Nix store, and that
variable is fixed when the process starts. A changed `config.toml` becomes a
*new* store path, which only a *new* process will ever see. So
`noctalia msg config-reload` faithfully re-reads the old file, and niri only
spawns noctalia at session start.

Two lines restart it in place, no logout:

```sh
pkill -f 'bin/noctalia$'
```
```sh
niri msg action spawn -- noctalia
```

- **`pkill -x noctalia` finds nothing.** The wrapper execs a binary called
  `.noctalia-wrapped`, so that is the process name. Hence the `-f` pattern.
- To watch it start and see any complaints, run it in a terminal instead:
  ```sh
  noctalia -d
  ```
- Logging out and back in (Mod+Ctrl+Shift+Q) works too, it is just slower.

---

## Keeping what you changed

### How it works

noctalia reads its settings from two files, in this order:

1. **`modules/programs/noctalia/config.toml`** — ours, baked into the Nix
   store at rebuild. Read-only.
2. **`~/.local/state/noctalia/settings.toml`** — written by noctalia itself,
   every time you change something in the settings window.

**The second one wins.** That is deliberate on noctalia's side: it means the
settings window keeps working even though our file is read-only.

And it has a very convenient consequence: that second file *is* the list of
your own changes, nothing else. So `noctalia-changes` just shows it to you,
and `--save` copies it into `config.toml`, comments and all.

### The procedure

- **Change things in the settings window** (Mod+Comma) until you like them.
  They take effect at once and survive a reboot — you are not in a hurry.
- **See what you changed:**
  ```sh
  noctalia-changes
  ```
- **Write it into the repo:**
  ```sh
  noctalia-changes --save
  ```
  That edits `modules/programs/noctalia/config.toml`.
- **Look at what was added:**
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git add -A
  ```
  ```sh
  git diff HEAD
  ```
- **Rebuild**, so the repo is what runs:
  ```sh
  nrs
  ```
- **Drop noctalia's own copy**, now that the same settings come from the repo:
  ```sh
  noctalia-changes --clear
  ```

### Why the last step matters

Skip `--clear` and the setting sits in **both** files with the same value.
Everything looks fine — until the day you change it in `config.toml` and
nothing happens, because noctalia's own file still wins. That is a genuinely
confusing half-hour, and it is entirely avoidable.

`--clear` keeps a copy next to the original (`settings.toml.bak`), and
noctalia notices within a second: it falls back to the config from the last
rebuild, so **nothing on screen changes.** That is the point — if something
*does* change, you forgot the `nrs`.

### Good to know

- **Don't want everything it found?** Run `noctalia-changes` without `--save`
  and copy just the parts you want into `config.toml` by hand. Or save
  everything, then undo the parts you don't want in Zed's git panel.
- **Something that should never be in the repo** — the wallpaper you picked is
  the obvious one — goes on an `# ignore:` line in `config.toml`. Deleting the
  line from `config.toml` is **not enough**: it is still in noctalia's own
  file, so the next `--save` writes it straight back.
- New settings are appended at the end of their section. Move them if it
  reads better; `--save` won't mind.
- **Colours and fonts are not in the settings window.** They come from the
  palette — see [theming.md](theming.md).
- A change to one bar lane saves that **whole lane** (`start`, `center` or
  `end`), because a list can only be replaced as a whole. That is normal, not
  a bug.
- `--save` **merges**: your comments and anything saved earlier stay put, only
  the keys you just changed are replaced. Saving twice in a row changes
  nothing.

The same pattern, for GTK apps that keep their settings in a database instead
of a file, is `dconf-changes` — see [settings.md](settings.md).

## Editing config.toml by hand

Perfectly fine, and the right thing for settings the GUI doesn't expose:

```sh
zeditor ~/flakeos/modules/programs/noctalia/config.toml
```
```sh
nrs
```

Then [restart it](#restarting-it).

Two safety nets:

- **The config is validated while the system is built** (`noctalia config
  validate`). A broken value fails the rebuild instead of leaving you with a
  bar that won't start. An unknown or misspelled key is only a warning —
  noctalia ignores it and says so in the build output, which is worth reading
  if a setting "doesn't work".
- If you set something in `config.toml` and nothing happens, the overwhelmingly
  likely cause is that the same key is still in noctalia's own file. Check:
  ```sh
  noctalia-changes
  ```

## When it breaks

- **The bar is gone.** Restart it in a terminal so you can see why:
  ```sh
  noctalia -d
  ```
- **Its log**, as part of the session journal:
  ```sh
  journalctl --user -b -g noctalia -e
  ```
- **A setting won't stick / won't change.** `noctalia-changes`, and read
  [Why the last step matters](#why-the-last-step-matters).
- **After an update it looks different or loses settings.** noctalia is a
  young project that still changes shape, and it is the one program here most
  likely to need work after an update. Why, and what to do:
  [updating.md](updating.md#where-the-risk-actually-sits).
- **Only one polkit agent per session.** noctalia can act as the password-prompt
  agent, but this config uses the GNOME one (`modules/system/polkit.nix`), so
  noctalia's stays off. Turning it on gets you a log line about an agent
  already existing and nothing else.
