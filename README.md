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
wallpapers/    your wallpapers, installed to /etc/wallpapers (pick one with Mod+W)
blueprints/    templates to copy into modules/ (not used by the system itself)
modules/
├── setup/     how the flake is wired + the disk layout (not day-to-day)
│   ├── parts.nix         flake-parts, wrapper library, `nix fmt`
│   └── disko.nix         ESP + ext4 root, shared by all hosts
├── system/    OS settings, one topic per file
│   ├── boot  nix  network  locale  audio  bluetooth  fonts  login  polkit  xdg
│   └── theme/            palette.nix (THE colours) + theme.nix (GTK/Qt/cursor/TTY)
├── programs/  one folder per program: <name>.nix + its native config file(s)
│   ├── niri/             niri.nix + config.kdl
│   ├── noctalia/         noctalia.nix + settings.json
│   ├── alacritty/        alacritty.nix + alacritty.toml
│   ├── zsh/              zsh.nix + zshrc
│   ├── zed/              zed.nix (+ palette theme) + settings.json
│   ├── git/  mpv/  mangohud/  (+ config file)    btop/  imv/  bat/  (settings inline)
│   ├── firefox/ thunar/ steam/ gamemode/ gamescope/ prismlauncher/ lutris/ openrgb/
│   ├── shortwave/ rnote/ rustdesk/ mediawriter/ claude-code/ fresh/
│   └── nix-tools/ (nixd, nil, alejandra)   cli/ (small tools, no config)
├── grouped/   bundles a host picks from
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

### Wrapped or not?

| wrapped (config baked in) | configured via NixOS options | why not wrapped |
|---|---|---|
| niri, noctalia, alacritty, zsh, git, btop, mpv, imv, mangohud, bat | firefox (policies) | nixpkgs already builds a wrapped Firefox from `policies` |
| zed (special case, see below) | | |
| | steam, lutris, prismlauncher | they keep their own state (library, accounts) |
| | shortwave, rnote, rustdesk, claude-code, fresh | same: stations, settings, IDs, logins are their own state |
| | mediawriter, nix-tools, cli | nothing to configure |
| | thunar | its settings live in xfconf, not a file |
| | gamemode, gamescope, openrgb | system services / need special permissions |

Things to know about wrapped programs:
- Config changes need a **rebuild**. Editing `~/.config/…` does nothing.
- Settings changed *inside* a wrapped program (btop options, noctalia's
  settings panel) don't survive a restart. **noctalia:** try settings in the
  GUI (Mod+Comma), run `dump-noctalia-shell`, then copy what you changed into
  `programs/noctalia/settings.json`.
- `git config --global` can't write; edit `programs/git/gitconfig`.
- **Zed** can't be pointed at a config file, so its wrapper links two files
  into `~/.config/zed/` before every start: `global_settings.json` (our
  defaults, from `programs/zed/settings.json`) and `themes/palette.json`
  ("Adwaita Dark (palette)", generated from the palette). Zed's own `settings.json` stays yours:
  changes made in Zed are saved there and win over our defaults.
- A wrapped program's config is the same for every user on the machine.

## Day to day

Aliases from `programs/zsh/zshrc`:

| alias | does |
|---|---|
| `nrs` | `sudo nixos-rebuild switch --flake ~/flakeos`: build + switch now |
| `nrb` | same, but only active after the next reboot |
| `nup` | update all inputs (`flake.lock`), then rebuild for the next boot |
| `nck` | `nix flake check`: does the config evaluate? |
| `ncg` | delete generations older than 30 days |

Each one also saves its full output to `logs/<kind>_<date>.log` in this repo
(e.g. `logs/rebuild_2026-09-12-14:03:22.log`). `logs/` is ignored by git;
delete the files whenever you like.

- The flake picks the config matching the hostname, so `nrs` is the same
  command on zeus and hermes.
- **New files must be `git add`ed**, or the flake doesn't see them (no error,
  your change is just missing). Committing isn't required.
- Broke something? Reboot and pick an older generation in the boot menu.
- **root is locked** (installed with `--no-root-passwd`): there is no root
  login and no `su`; `sudo` with your own password does everything.
- **Locked out?** A rebuild broke sudo → boot an older generation. Forgot
  your password (passwords aren't part of generations) → boot the NixOS ISO,
  then:
  ```sh
  sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
  sudo nixos-enter --root /mnt -c 'passwd slider'
  ```
- `nix fmt .` formats all Nix files.
- **Default apps** (which program opens which file type) are set in each
  program's module via `xdg.mime.defaultApplications`: videos/audio → mpv,
  images → imv, folders → Thunar, archives → xarchiver, links/PDFs → Firefox.
- **New wallpaper:** put it in `wallpapers/`, `git add`, rebuild, then Mod+W.

### Keys worth knowing

| key | action |
|---|---|
| Mod+Space | launcher |
| Mod+Return / B / E / Z / G | alacritty / Firefox / Thunar / Zed / Steam |
| Mod+W | pick wallpaper |
| Mod+Comma | noctalia settings |
| Mod+Alt+L | session menu (lock, suspend, reboot, power off) |
| Mod+BackSpace | overview of all key binds |

### Adding things
Start from a template in [`blueprints/`](blueprints): programs (wrapped,
wrapped by hand, plain, from another flake), system settings, bundles, users
and hosts. Its README says which one to pick and the five steps to use it.

## Installing (fresh)

> **zeus: back up first.** The install wipes the 1 TB system drive, which is
> where `/home/slider` lives right now, including `~/flakeos` and `~/nixos`.
> Push this repo somewhere (a private GitHub/Codeberg repo) or copy it to the
> 2 TB data drive. The 2 TB data drive itself is never touched.

1. Boot the NixOS ISO, connect to the network, and get the repo:
   ```sh
   git clone https://github.com/slider104/flakeos.git /tmp/flakeos && cd /tmp/flakeos
   ```
2. Check the disk. `ls -l /dev/disk/by-id/ | grep -v part` must list the
   device in `modules/hosts/<host>/disko.nix` (for hermes: fill it in now).
3. **hermes only:** put the real hardware scan into
   `modules/hosts/hermes/hardware.nix` (paste the body of
   `nixos-generate-config --show-hardware-config --no-filesystems`), then `git add -A`.
4. Partition, format and mount (**erases that disk**):
   ```sh
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --flake .#zeus
   ```
5. Install and reboot:
   ```sh
   sudo nixos-install --flake .#zeus --no-root-passwd
   reboot
   ```
6. You're logged into niri automatically. Open a terminal (Mod+Return) and:
   ```sh
   passwd                                   # initial password is "slider"
   git clone <your-repo-url> ~/flakeos
   ```
   Then press Mod+W to pick a wallpaper.
