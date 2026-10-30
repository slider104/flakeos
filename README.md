# flakeos

A minimal NixOS config for **zeus** (gaming desktop) and **hermes** (laptop):
niri + noctalia, one Adwaita-dark look everywhere, ready for gaming. No
home-manager.

It's a config for two real machines rather than a framework, so you can read
it, copy pieces out of it, or install the whole thing and make it yours:
[wiki/install.md](wiki/install.md) goes from a USB stick to a working desktop
in about an hour, and its last step swaps the personal bits (name, hosts,
locale, keyboard) for yours. Everything is explained for someone who has
never used NixOS — the [wiki](wiki/README.md) is the long version of this
page.

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
   Zed, MangoHud, imv and the TTY. So it all looks like one system. (The RGB
   lights on zeus keep their own cyan, set in `programs/openrgb/openrgb.nix`.)

## Layout

```
assets/                   just assets like logos for the system (not wallpapers)
wallpapers/               your wallpapers, installed to /etc/wallpapers (pick one with Mod+W)
wiki/                     the guides: one file per topic (see below)
blueprints/               templates to copy into modules/ (not used by the system itself)
modules/
├── setup/                how the flake is wired + the disk layout (not day-to-day)
│   ├── parts.nix         flake-parts, wrapper library, `nix fmt`
│   └── disko.nix         ESP + ext4 root, shared by all hosts
├── system/               OS settings, one topic per file
│   ├── audio  bluetooth  boot  dconf  fonts  libvirt  locale  login  network
│   ├── nix  nix-ld  polkit  reboot  stable  xdg
│   └── theme/            palette.nix (THE colours) + theme.nix (GTK/Qt/cursor/TTY)
├── programs/             one folder per program: <name>.nix + its native config file(s)
│   ├── niri/             niri.nix + config.kdl
│   ├── noctalia/         noctalia.nix + config.toml + noctalia-changes.py
│   ├── alacritty/        alacritty.nix + alacritty.toml
│   ├── zsh/              zsh.nix + zshrc
│   ├── zed/              zed.nix (+ palette theme) + settings.json
│   ├── git/  mpv/  mangohud/  (+ config file)    btop/  imv/  bat/  (settings inline)
│   ├── firefox/ brave/ thunar/ steam/ gamemode/ gamescope/ prismlauncher/ lutris/
│   ├── shortwave/ rnote/ libreoffice/ rustdesk/ mediawriter/ claude-code/ fresh/
│   ├── virt-manager/     the window for virtual machines
│   ├── openrgb/ corsair/ the RGB lighting and the mouse's side buttons (zeus)
│   ├── ydotool/          the Autoclicker
│   └── nix-tools/ (nixd, nil, alejandra)   cli/ (small tools, no config)
├── grouped/              bundles a host picks from
│   ├── base.nix          every machine: boot, nix, network, locale, zsh, git, btop, bat, cli, …
│   ├── desktop.nix       login, polkit, audio, theme, niri, noctalia, alacritty, browsers, zed, apps, …
│   ├── gaming.nix        steam, gamemode, gamescope, mangohud, prismlauncher, lutris
│   └── vm.nix            virtual machines: KVM/QEMU/libvirt + virt-manager
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
  base desktop gaming vm     # grouped/
  openrgb corsair            # single programs, just for zeus
  slider                     # users/
];
```

## The wiki

The detailed guides live in [`wiki/`](wiki/README.md), one file per topic. No
previous knowledge assumed, and no page assumes you read another one first.

| you want to… | read |
|---|---|
| understand the terminal, how NixOS thinks, what every command does | [wiki/general.md](wiki/general.md) |
| install flakeos on a PC, or reinstall a configured host like zeus | [wiki/install.md](wiki/install.md) |
| learn the window manager properly: the strip, every key, window rules | [wiki/niri.md](wiki/niri.md) |
| work with the bar, launcher and notifications — and keep your changes | [wiki/noctalia.md](wiki/noctalia.md) |
| know where a program's settings live and whether they survive a reinstall | [wiki/settings.md](wiki/settings.md) |
| change colours, fonts, cursor or icons | [wiki/theming.md](wiki/theming.md) |
| game: Steam, Proton, GameMode, gamescope, MangoHud, Lutris | [wiki/gaming.md](wiki/gaming.md) |
| run another operating system in a window | [wiki/virtualisation.md](wiki/virtualisation.md) |
| add a program, a system setting, a bundle, a user or a machine | [wiki/blueprints.md](wiki/blueprints.md) |
| update, and know exactly how to get back if it goes wrong | [wiki/updating.md](wiki/updating.md) |
| commit, push, pull, and keep two machines in step | [wiki/git.md](wiki/git.md) |
| **fix something that's broken**: logs, services, rollbacks, recovery | [wiki/troubleshoot.md](wiki/troubleshoot.md) |
| sound, Bluetooth, monitors, RGB, the mouse, the data drive | [wiki/hardware.md](wiki/hardware.md) |

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
| Mod+Shift+B | Brave (the 2nd browser, for WebHID sites) |
| Mod+Q | close the window |
| Mod+Left / Mod+Right | focus the column left / right (Up / Down: windows inside a column) |
| Mod+Ctrl+arrow keys | move the window / column |
| Mod+F | make the column full width (again: back) |
| Mod+Shift+F | fullscreen |
| Mod+Shift+R | cycle column width: 1/3, 1/2, 2/3 |
| Mod+A | make the window floating, or tile it again |
| Mod+O | overview of all windows and workspaces |
| Mod+1 … Mod+9 | go to workspace 1 … 9 (Mod+Shift+1 … 9: take the window along) |
| Mod+Page_Up / Page_Down | workspace above / below |
| Mod+S / Mod+Ctrl+S / Mod+Shift+S | screenshot of the window / the monitor / a region (saved to `~/Pictures/Screenshots`, also copied) |
| Mod+W | pick a wallpaper |
| Mod+N | notification history |
| Mod+Comma | noctalia settings |
| Mod+Alt+L | session menu: lock, suspend, reboot, power off |
| Mod+Escape | a game or VM swallows all shortcuts? This gives them back |

All binds live in `programs/niri/config.kdl` (section `binds`). Each has a
`hotkey-overlay-title`, which is the text Mod+BackSpace shows. The full list,
with the layout model explained: [wiki/niri.md](wiki/niri.md).

## Terminal commands

The shell is zsh. These aliases are defined in `programs/zsh/zshrc`:

| command | does |
|---|---|
| `nrs` | **rebuild** the system from `~/flakeos` and switch to it right away |
| `nrb` | rebuild, but only switch at the next boot (for big changes, e.g. after an update) |
| `nup` | **update**: fetch the newest versions of everything (`flake.lock`), build, use at the next boot. Build fails? `flake.lock` is put back |
| `ndb` | **dry build**: check this machine's config for errors and list what a rebuild would build and download, without building it |
| `nck` | check the config for errors without building anything |
| `ncg` | delete old system versions (generations) older than 30 days, frees disk space |
| `ll` | `ls -lah`: list all files with sizes |
| `noctalia-changes` | show what you changed in noctalia's settings window ([guide](wiki/noctalia.md)) |
| `dconf-changes` | show what you changed in a GTK app that saves its own settings (rnote, Shortwave, virt-manager) ([guide](wiki/settings.md)) |

- `nrs`, `nrb`, `nup`, `ndb` work the same on every machine: the flake picks
  the config whose name matches the hostname (`zeus`, `hermes`).
- `ndb` before `nrs`/`nrb` when you changed a lot: it reads the whole config
  for **this** machine and stops at the recipes instead of building them, so
  it finds a typo or a wrong option name in seconds and needs no password.
  `nck` asks the wider question: it checks **every** host and module in the
  flake, so it also catches breaking the other machine. Use it before you
  push. Neither one can find errors that only show up while a package is being
  built.
- Each alias shows its output as usual **and** saves it to
  `~/flakeos/logs/<kind>_<date>.log`. Handy when an error scrolled away.
  `logs/` is ignored by git; delete the files whenever you like.
- Old generations are also deleted automatically once a week
  (`system/nix.nix`), so `ncg` is only needed when the disk gets full.
- `nix fmt .` (in `~/flakeos`) tidies up the formatting of all Nix files.

Which command when, and everything else a terminal can do for you:
[wiki/general.md](wiki/general.md).

## Changing something

**How it works:** the files in `~/flakeos` *are* the system. A rebuild
(`nrs`) reads them and builds a complete new system version, a *generation*,
then switches to it. The old one stays on disk and in the boot menu, so a
broken change is never a disaster
([wiki/troubleshoot.md](wiki/troubleshoot.md)).

- Open the repo in Zed (or press Mod+Z and open `~/flakeos`):
  ```sh
  zeditor ~/flakeos
  ```
- Change the file (see the table below for which one).
- **Made a new file?** Tell git, or the flake doesn't see it (no error, your
  change is just missing):
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
  them. For the bar (noctalia), see
  [wiki/noctalia.md](wiki/noctalia.md#restarting-it).

## Where do I change…?

| what | file (in `modules/`) |
|---|---|
| keyboard layout | `system/locale.nix` (text console) **and** `programs/niri/config.kdl` (desktop, `layout "de"`) |
| time zone, date / number formats | `system/locale.nix` |
| key binds, gaps, window rules, mouse / touchpad | `programs/niri/config.kdl` — guide: [wiki/niri.md](wiki/niri.md) |
| colours, fonts, cursor, icons | `system/theme/palette.nix` — guide: [wiki/theming.md](wiki/theming.md) |
| bar, launcher, notifications, weather location | noctalia's settings window + `noctalia-changes`, or `programs/noctalia/config.toml` — guide: [wiki/noctalia.md](wiki/noctalia.md) |
| terminal (see-through, font size) | `programs/alacritty/alacritty.toml` |
| aliases, prompt, shell history | `programs/zsh/zshrc` |
| git name and e-mail | `programs/git/gitconfig` |
| Firefox extensions and settings | `programs/firefox/firefox.nix` |
| Brave extensions and settings (2nd browser) | `programs/brave/brave.nix` |
| Zed defaults | `programs/zed/settings.json` (changes made *inside* Zed are saved by Zed itself) |
| video player | `programs/mpv/mpv.conf` |
| in-game overlay | `programs/mangohud/MangoHud.conf` — guide: [wiki/gaming.md](wiki/gaming.md) |
| virtual machines | `system/libvirt.nix` (the machinery), `programs/virt-manager/virt-manager.nix` (the window) — guide: [wiki/virtualisation.md](wiki/virtualisation.md) |
| small command-line tools | `programs/cli/cli.nix` |
| which programs a machine gets | `grouped/*.nix` and `hosts/<host>/<host>.nix` |
| which app opens which file type | the program's own `.nix` file, see [wiki/general.md](wiki/general.md#7-which-app-opens-which-file) |
| automatic cleanup, unfree software | `system/nix.nix` |
| a package on unstable is broken | `system/stable.nix` — guide: [wiki/updating.md](wiki/updating.md#when-a-package-doesnt-build) |
| settings a program saves by itself (rnote, Shortwave, virt-manager) | nothing to edit by hand: `dconf-changes <program> --save` — guide: [wiki/settings.md](wiki/settings.md) |
| autoclicker | the Autoclicker window (saves by itself); how it works: `programs/ydotool/ydotool.nix` |
| RGB colours (zeus) | `programs/openrgb/openrgb.nix` — guide: [wiki/hardware.md](wiki/hardware.md#rgb-lighting-zeus) |
| the mouse's side buttons (zeus) | `programs/corsair/corsair.nix` — guide: [wiki/hardware.md](wiki/hardware.md#the-corsair-mouse-zeus) |
| the data drive (zeus) | `hosts/zeus/zeus.nix` |

Adding something new (a program, a setting, a user, a machine) is explained
step by step in [wiki/blueprints.md](wiki/blueprints.md).

## Wallpapers

Mod+W picks a picture from `wallpapers/` (repo root); it stays across logins
(noctalia remembers it).

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

Want it to change by itself instead? Add a `[wallpaper.automation]` section to
`programs/noctalia/config.toml`:

```toml
[wallpaper.automation]
enabled = true
interval_seconds = 1800
order = "random"
```

## Something broke?

Short answers:

- **The rebuild failed:** nothing changed, you're still on the old system. The
  last lines of the error name the file and line; the full output is in
  `~/flakeos/logs/`.
- **The rebuild worked, but now something is broken:** reboot, and in the boot
  menu (shown for 5 seconds) pick an older generation. Fix the file, `nrs`
  again.
- **A change doesn't show up:** new file not `git add`ed? Program still open
  from before the rebuild?

The long answers — all the logs, every service, the rollbacks, and what to do
when you're locked out — are in
[wiki/troubleshoot.md](wiki/troubleshoot.md).
