# The flakeos wiki

One page per topic. Everything is written for someone who has never used
NixOS, and nothing assumes you read another page first.

The [main README](../README.md) is the short version: what flakeos is, the
keys, the commands, and where to change what. This folder is the long
version.

## Which page do I want?

**Getting started**

| page | what's in it |
|---|---|
| [general.md](general.md) | the terminal, how NixOS thinks, every flakeos command explained, where files live. **Start here if anything below looks like a foreign language.** |
| [install.md](install.md) | install flakeos on a PC from scratch, or reinstall a machine that's already in the repo |

**Using the system**

| page | what's in it |
|---|---|
| [niri.md](niri.md) | the window manager: the scrolling strip, every key bind, floating windows, monitors, workspaces, screenshots |
| [noctalia.md](noctalia.md) | the bar, launcher, notifications, control center, lock screen, wallpapers — and how to keep what you change in its settings window |
| [settings.md](settings.md) | the four ways a program's settings are kept here, why editing `~/.config` often does nothing, and `dconf-changes` |
| [theming.md](theming.md) | the palette: colours, fonts, cursor, icons. Change one value, the whole system follows |
| [gaming.md](gaming.md) | Steam, Proton, GameMode, gamescope, MangoHud, Lutris, Prism Launcher, controllers, non-Steam games |
| [virtualisation.md](virtualisation.md) | another operating system in a window: Virtual Machine Manager, the settings that matter, the clipboard |

**Changing the system**

| page | what's in it |
|---|---|
| [blueprints.md](blueprints.md) | add a program, a system setting, a bundle, a user or a machine — and remove them again |
| [updating.md](updating.md) | `nup`, what an update can cost you, the three ways back, and what to do when a package won't build |
| [git.md](git.md) | commit, push, pull, the SSH key, and keeping two machines in step |

**When it goes wrong**

| page | what's in it |
|---|---|
| [troubleshoot.md](troubleshoot.md) | all the logs, services, generations and rollbacks. The page to open when something is broken |
| [hardware.md](hardware.md) | sound, Bluetooth, monitors, the graphics card, RGB lighting, the Corsair mouse, the autoclicker, the data drive |

## How to read these pages

- Every command sits in its own box, so you can copy it with the mouse. The
  line above says what it does.
- Commands run inside the repo unless a page says otherwise. Open a terminal
  (**Mod+Return**) and go there first:
  ```sh
  cd ~/flakeos
  ```
- Paths like `programs/zsh/zshrc` are inside `modules/`. Paths starting with
  `wiki/` or `blueprints/` are from the repo root.
- Copy and paste in the terminal is **Ctrl+Shift+C** and **Ctrl+Shift+V**
  (plain Ctrl+C stops the running command instead).
- Never read a page to the end before typing? At least read the current
  *step* to the end. A few of them erase disks.

## Adding to the wiki

A new page is just a new `.md` file in this folder plus a line in the table
above. Nothing reads these files but you — they are not part of the build, so
a typo here can't break the system, and no rebuild is needed after editing
one.
