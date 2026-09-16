# flakeos

A minimal NixOS config for **zeus** (gaming desktop) and **hermes** (laptop):
niri + noctalia, one Adwaita-dark look everywhere, ready for gaming. No home-manager.

## The three ideas

1. **Dendritic.** `flake.nix` hands *every* `.nix` file under `modules/` to
   flake-parts ([import-tree](https://github.com/vic/import-tree)). No file
   imports another by path. Each file *publishes* something under a name
   (`flake.nixosModules.<name>`), and other files use it by that name
   (`self.nixosModules.<name>`). A new file is picked up as soon as it's
   `git add`ed.

2. **Wrapping instead of home-manager.** A wrapped program is the program plus
   its config, built into one package: `alacritty` always starts with
   `--config-file /nix/store/…`. Nothing is written into `$HOME`, and
   `~/.config/<program>` is ignored. Uses
   [nix-wrapper-modules](https://github.com/nix-community/nix-wrapper-modules).
   A side effect: every wrapped program can run on any machine with Nix,
   e.g. `nix run .#alacritty`.

3. **One palette.** GTK apps use the standard adw-gtk3-dark theme, and
   `modules/system/theme/palette.nix` holds the same Adwaita-dark colours
   (plus fonts and cursor) for everything else: alacritty, niri, noctalia,
   Zed, MangoHud, imv and the TTY. So it all looks like one system. (Your RGB
   lights keep their own cyan, set in `programs/openrgb/openrgb.nix`.)

## Layout

```
assets/                   just assets like logos for the system (not wallpapers)
wallpapers/               your wallpapers, installed to /etc/wallpapers (pick one with Mod+W)
blueprints/               templates to copy into modules/ (not used by the system itself)
modules/
├── setup/                how the flake is wired + the disk layout (not day-to-day)
│   ├── parts.nix         flake-parts, wrapper library, `nix fmt`
│   ├── disko.nix         ESP + ext4 root, shared by all hosts
│   └── README.md         the installation guide
├── system/               OS settings, one topic per file
│   ├── boot  nix  network  locale  audio  bluetooth  fonts  login  polkit  xdg
│   └── theme/            palette.nix (THE colours) + theme.nix (GTK/Qt/cursor/TTY)
├── programs/             one folder per program: <name>.nix + its native config file(s)
│   ├── niri/             niri.nix + config.kdl
│   ├── noctalia/         noctalia.nix + settings.json
│   ├── alacritty/        alacritty.nix + alacritty.toml
│   ├── zsh/              zsh.nix + zshrc
│   ├── zed/              zed.nix (+ palette theme) + settings.json
│   ├── git/  mpv/  mangohud/  (+ config file)    btop/  imv/  bat/  (settings inline)
│   ├── firefox/ thunar/ steam/ gamemode/ gamescope/ prismlauncher/ lutris/ openrgb/
│   ├── shortwave/ rnote/ libreoffice/ rustdesk/ mediawriter/ claude-code/ fresh/
│   └── nix-tools/ (nixd, nil, alejandra)   cli/ (small tools, no config)
├── grouped/              bundles a host picks from
│   ├── base.nix          every machine: boot, nix, network, locale, zsh, git, btop, bat, cli
│   ├── desktop.nix       login, polkit, audio, theme, niri, noctalia, alacritty, firefox, zed, apps, ...
│   └── gaming.nix        steam, gamemode, gamescope, mangohud, prismlauncher, lutris
├── users/
│   └── slider.nix
└── hosts/
    ├── zeus/             zeus.nix (what it gets) + hardware.nix + disko.nix
    └── hermes/           same shape
```

A host file just lists what the machine gets:

```nix
modules = with self.nixosModules; [
  zeus-hardware zeus-disko   # this machine
  base desktop gaming        # grouped/
  openrgb                    # a single program, just for zeus
  slider                     # users/
];
```

## Which README?

| you want to… | read |
|---|---|
| use the system every day: keys, commands, where to change what | this file, below |
| add a program, a system setting, a bundle, a user or a machine | [`blueprints/README.md`](blueprints/README.md) |
| install flakeos on a PC, or reinstall a configured host like zeus | [`modules/setup/README.md`](modules/setup/README.md) |

---

# Day to day

Everything below assumes the repo lives in `~/flakeos`. Paths like
`programs/zsh/zshrc` are inside `modules/`.

## Keys worth knowing

**Mod** is the Windows (Super) key.

niri is a *scrolling* window manager: every new window opens as a column on
the right, and the columns form one long strip you scroll through. Nothing
gets squeezed smaller when you open more windows. Workspaces sit *below*
each other (up/down), each with its own strip.

| key | does |
|---|---|
| **Mod+BackSpace** | **show all key binds** (when you forgot one) |
| Mod+Space | app launcher (type to search, Enter to start) |
| Mod+Return | terminal (alacritty) |
| Mod+B / Mod+E / Mod+Z / Mod+G | Firefox / files (Thunar) / Zed / Steam |
| Mod+Q | close the window |
| Mod+Left / Mod+Right | focus the column left / right (Up / Down: windows inside a column) |
| Mod+Ctrl+arrow keys | move the window / column |
| Mod+F | make the column full width (again: back) |
| Mod+Shift+F | fullscreen |
| Mod+Shift+R | cycle column width: 1/3, 1/2, 2/3 |
| Mod+O | overview of all windows and workspaces |
| Mod+1 … Mod+9 | go to workspace 1 … 9 (Mod+Shift+1 … 9: take the window along) |
| Mod+Page_Up / Page_Down | workspace above / below |
| Mod+S / Mod+Ctrl+S | screenshot of the window / the monitor (saved to `~/Pictures/Screenshots`, also copied) |
| Mod+W | pick a wallpaper |
| Mod+N | notification history |
| Mod+Comma | noctalia settings (see [Keeping noctalia settings](#keeping-noctalia-settings)) |
| Mod+Alt+L | session menu: lock, suspend, reboot, power off |
| Mod+Escape | a game or VM swallows all shortcuts? This gives them back |

All binds live in `programs/niri/config.kdl` (section `binds`). Each has a
`hotkey-overlay-title`, which is the text Mod+BackSpace shows.

## Terminal commands

The shell is zsh. These aliases are defined in `programs/zsh/zshrc`:

| command | does |
|---|---|
| `nrs` | **rebuild** the system from `~/flakeos` and switch to it right away |
| `nrb` | rebuild, but only switch at the next boot (for big changes, e.g. after an update) |
| `nup` | **update**: fetch the newest versions of everything (`flake.lock`), then `nrb` |
| `nck` | check the config for errors without building anything |
| `ncg` | delete old system versions (generations) older than 30 days, frees disk space |
| `ll` | `ls -lah`: list all files with sizes |
| `noctalia-changes` | show what you changed in noctalia's settings panel (see below) |

- `nrs`, `nrb`, `nup` work the same on every machine: the flake picks the
  config whose name matches the hostname (`zeus`, `hermes`).
- Each alias shows its output as usual **and** saves it to
  `~/flakeos/logs/<kind>_<date>.log` (e.g. `logs/rebuild_2026-09-12-14:03:22.log`).
  Handy when an error scrolled away. `logs/` is ignored by git; delete the
  files whenever you like.
- Old generations are also deleted automatically once a week
  (`system/nix.nix`), so `ncg` is only needed when the disk gets full.
- `nix fmt .` (in `~/flakeos`) tidies up the formatting of all Nix files.

## Changing something

**How it works:** the files in `~/flakeos` *are* the system. A rebuild
(`nrs`) reads them and builds a complete new system version, a
*generation*, then switches to it. The old one stays on disk and in the boot
menu, so a broken change is never a disaster (see
[Something broke?](#something-broke)).

- Open the repo in Zed (or press Mod+Z and open `~/flakeos`):
  ```sh
  zeditor ~/flakeos
  ```
- Change the file (see the table below for which one).
- **Made a new file?** Tell git about it, or the flake doesn't see it (no
  error, your change is just missing):
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git add -A
  ```
- Rebuild and switch:
  ```sh
  nrs
  ```
- Programs that are already open keep their old config. Close and reopen
  them. For the bar (noctalia), log out and back in: Mod+Ctrl+Shift+Q, then
  log in on the text login screen.

## Where do I change…?

| what | file (in `modules/`) |
|---|---|
| keyboard layout | `system/locale.nix` (text console) **and** `programs/niri/config.kdl` (desktop, `layout "de"`) |
| time zone, date / number formats | `system/locale.nix` |
| key binds, gaps, window rules, mouse / touchpad | `programs/niri/config.kdl` |
| colours, fonts, cursor, icons | `system/theme/palette.nix` |
| bar, launcher, notifications, weather location | noctalia's settings panel + `noctalia-changes`, or `programs/noctalia/settings.json` |
| terminal (see-through, font size) | `programs/alacritty/alacritty.toml` |
| aliases, prompt, shell history | `programs/zsh/zshrc` |
| git name and e-mail | `programs/git/gitconfig` |
| Firefox extensions and settings | `programs/firefox/firefox.nix` |
| Zed defaults | `programs/zed/settings.json` (changes made *inside* Zed are saved by Zed itself) |
| video player | `programs/mpv/mpv.conf` |
| in-game overlay | `programs/mangohud/MangoHud.conf` |
| small command-line tools | `programs/cli/cli.nix` |
| which programs a machine gets | `grouped/*.nix` and `hosts/<host>/<host>.nix` |
| which app opens which file type | the program's own `.nix` file, see [Default apps](#default-apps) |
| automatic cleanup, unfree software | `system/nix.nix` |
| autoclicker | the Autoclicker window (saves by itself); how it works: `programs/ydotool/ydotool.nix` |
| RGB colours (zeus) | `programs/openrgb/openrgb.nix` |
| the data drive (zeus) | `hosts/zeus/zeus.nix` |

Adding something new (a program, a setting, a user) is explained step by
step in [`blueprints/README.md`](blueprints/README.md).

## Things to know about wrapped programs

niri, noctalia, alacritty, zsh, git, btop, mpv, imv, mangohud and bat are
*wrapped*: their config is baked into the program at rebuild.

- Config changes need a **rebuild**. Editing `~/.config/…` does nothing.
- Settings changed *inside* a wrapped program (btop options, noctalia's
  settings panel) don't survive a restart. For noctalia there's a command
  that makes them permanent, see
  [Keeping noctalia settings](#keeping-noctalia-settings).
- `git config --global` can't write; edit `programs/git/gitconfig`.
- **Zed** can't be pointed at a config file, so its wrapper links two files
  into `~/.config/zed/` before every start: `global_settings.json` (our
  defaults, from `programs/zed/settings.json`) and `themes/palette.json`
  ("Adwaita Dark (palette)", generated from the palette). Zed's own
  `settings.json` stays yours: changes made in Zed are saved there and win
  over our defaults.
- A wrapped program's config is the same for every user on the machine.

## Updating

**How it works:** `flake.lock` pins the exact version of nixpkgs (all
programs) and the other inputs. Nothing updates by itself; you decide when.
`nup` moves the pins to the newest versions and builds the new system for
the next boot.

- Update and build:
  ```sh
  nup
  ```
- Reboot to use it:
  ```sh
  reboot
  ```
- Something doesn't work after the update? Pick the previous generation in
  the boot menu. `flake.lock` is in git, so `git diff flake.lock` shows what
  moved, and `git checkout flake.lock` goes back to the old versions.

## Default apps

Which program opens which file type is set in each program's own module
(`xdg.mime.defaultApplications`):

| files | open in |
|---|---|
| videos, music | mpv |
| images | imv |
| folders | Thunar |
| archives (zip, 7z, rar, tar) | xarchiver |
| web links, HTML, PDFs | Firefox |
| text files | Zed |
| office documents | LibreOffice |

Check which app a type goes to:

```sh
xdg-mime query default image/png
```

## Wallpapers

Mod+W picks a picture from `wallpapers/` (repo root); it stays across
logins. Want a random one on every login instead? That's already there,
just commented out: uncomment the block in `prepareStart` in
`programs/noctalia/noctalia.nix` and rebuild.

- Put the picture into `~/flakeos/wallpapers/`, then:
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git add -A
  ```
  ```sh
  nrs
  ```
- Press Mod+W and pick it.

## Keeping noctalia settings

**How it works:** noctalia's real settings are
`programs/noctalia/settings.json`, baked in at rebuild. The settings panel
(Mod+Comma) is great for trying things out, but its changes are gone after
the next login. When noctalia starts, it takes a snapshot of its settings
(`~/.cache/noctalia/settings-at-start.json`, via the startup hook in
`settings.json`), and `noctalia-changes` compares the live settings against
that snapshot. So it shows **only what you changed** (e.g.
`"bar": {"displayMode": "auto_hide"}`), not noctalia's hundreds of other
settings.

- Change things in the panel (Mod+Comma) until you like them.
- Show what you changed:
  ```sh
  noctalia-changes
  ```
- Add it to `programs/noctalia/settings.json`:
  ```sh
  noctalia-changes --save
  ```
- Look at what was added:
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git diff
  ```
- Rebuild; now it's permanent:
  ```sh
  nrs
  ```

Good to know:
- Don't want everything it found? Run `noctalia-changes` without `--save`
  and copy just the parts you want into `settings.json` by hand. Or save,
  then undo parts in Zed's git panel.
- "No snapshot yet": noctalia was started before the snapshot existed. Log
  out and back in once.
- After `--save`, running it again shows only newer changes. A change to a
  bar widget saves that whole section's widget list (left, center or right),
  so that part of `settings.json` gets long; that's normal.
- Colours are not in the panel's settings: they come from the palette
  (`system/theme/palette.nix`).
- The wallpaper you pick with Mod+W isn't a setting (see
  [Wallpapers](#wallpapers)).

## Gaming

Steam comes with Proton-GE (Steam → a game → Properties → Compatibility).
Three helpers go into a game's **launch options** (Steam → a game →
Properties → General):

| launch options | does |
|---|---|
| `gamemoderun %command%` | GameMode: CPU/GPU in performance mode while the game runs |
| `mangohud %command%` | in-game overlay: FPS, temperatures, load (toggle: Right Shift + F12) |
| `gamescope -W 2560 -H 1440 -f -- %command%` | runs the game inside its own small compositor: fixed resolution, upscaling, frame limit (helps games that struggle with fullscreen or resolution) |

They can be combined: `gamemoderun mangohud %command%`.

- The very first Steam start downloads ~500 MB of updates, it just looks
  stuck. Wait.
- Minecraft: Prism Launcher. Battle.net, GOG and emulators: Lutris.

## Saving changes to GitHub

**How it works:** git keeps the history of the repo. A *commit* is a saved
snapshot with a short message, *push* uploads your commits to GitHub,
*pull* downloads commits made on the other machine. Zed's git panel does all
of this with buttons; in a terminal:

- Go to the repo:
  ```sh
  cd ~/flakeos
  ```
- See what changed:
  ```sh
  git status
  ```
- Mark everything for the next commit (new files too):
  ```sh
  git add -A
  ```
- Save a snapshot with a short description:
  ```sh
  git commit -m "what I changed"
  ```
- Upload to GitHub:
  ```sh
  git push
  ```
- On the other machine, get the changes (then `nrs`):
  ```sh
  git pull
  ```

Pushing uses your SSH key `~/.ssh/id_ed25519`, never a password or token.
`programs/git/gitconfig` sends pushes to GitHub over SSH, even though the
repo was cloned with an `https://` URL, and `programs/git/git.nix` already
trusts GitHub's host key. So once the key is on the machine, pushing from
Zed just works. `ssh -T git@github.com` checks the key: it should answer
"Hi slider104!". No key yet, or your own GitHub repo? See
[the install guide](modules/setup/README.md#optional-your-own-github-repo).

## Two machines

**How it works:** GitHub is the meeting point. Each machine has its own copy
of the repo, and they only line up once one machine pushes and the other
pulls. `programs/git/gitconfig` sets `pull.rebase = true`: when both machines
made commits, a pull puts your local commits on top of the ones from GitHub,
so the history stays a straight line.

- Before editing on a machine, get the latest state first. This avoids most
  trouble:
  ```sh
  git pull
  ```
- Changed something on machine A: commit and push there, then on machine B:
  ```sh
  git pull
  nrs
  ```
- B has uncommitted changes, so the pull refuses ("cannot pull with rebase:
  You have unstaged changes"). Commit them first, or park them during the
  pull:
  ```sh
  git pull --autostash
  ```
- Both machines made commits: `git pull` on B stacks B's commits on top,
  then `git push` from B and `git pull` on A.
- Both changed the same lines: the pull stops with a conflict. Fix the file
  (git marks the spot with `<<<<<<<` and `>>>>>>>`), then:
  ```sh
  git add <file>
  git rebase --continue
  ```
  Or give up and go back to how it was before the pull:
  ```sh
  git rebase --abort
  ```
- Updates: run `nup` on **one** machine only, commit and push `flake.lock`.
  The other machine pulls and runs `nrs`, and gets exactly the same versions.
  Ran `nup` on both and now `flake.lock` conflicts? Keep the one from GitHub
  (in a rebase, `--ours` is the GitHub side), then `nrs` so this machine
  builds those versions instead of its own discarded update:
  ```sh
  git checkout --ours flake.lock
  git add flake.lock
  git rebase --continue
  nrs
  ```
  `flake.lock` is a normal file in git: after a pull, both machines have the
  same one. They only drift apart if one runs `nup` and doesn't push.

## Something broke?

- **The rebuild failed:** nothing changed, you're still on the old system.
  The last lines of the error name the file and line. The full output is in
  `~/flakeos/logs/`.
- **The rebuild worked, but now something is broken:** reboot, and in the
  boot menu (shown for 5 seconds) pick an older generation. Fix the file,
  `nrs` again.
- **A change doesn't show up:** new file not `git add`ed? Program still
  open from before the rebuild? (see [Changing something](#changing-something))
- **root is locked** (installed with `--no-root-passwd`): there is no root
  login and no `su`; `sudo` with your own password does everything.
- **Locked out?** A rebuild broke sudo → boot an older generation. Forgot
  your password (passwords aren't part of generations) → boot the NixOS
  installer USB stick, then:
  ```sh
  sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
  ```
  ```sh
  sudo nixos-enter --root /mnt -c 'passwd slider'
  ```
  ```sh
  reboot
  ```
