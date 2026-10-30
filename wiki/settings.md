# Settings: where they live and how to keep them

The question this page answers: **"I changed something — will it still be
there after a reinstall?"**

On a normal Linux you change a setting in a program and forget about it. Here
there are four different answers depending on the program, and knowing which
is which saves a lot of confusion. The short version:

| kind | example | kept by |
|---|---|---|
| **wrapped**: takes a config file or flag | niri, alacritty, mpv, zsh, git, btop, bat, imv, MangoHud, noctalia | the file in `modules/programs/<name>/`. Edit it, rebuild |
| **dconf**: a GTK app with no config file | rnote, Shortwave, virt-manager, the file picker | `dconf-changes <name> --save` |
| **reads `/etc/xdg/…` too** | Thunar's right-click menu, GTK fonts | `environment.etc."xdg/…"` in its module |
| **own format, own place** | Steam, Lutris, Firefox profiles, Zed's own settings | not kept — set it up again |

## Contents

- [Wrapped programs](#wrapped-programs)
  - [What wrapping means](#what-wrapping-means)
  - [The rules that follow from it](#the-rules-that-follow-from-it)
  - [The exceptions](#the-exceptions)
- [dconf: GTK apps with no config file](#dconf-gtk-apps-with-no-config-file)
  - [How it works](#how-it-works)
  - [Does my program work this way?](#does-my-program-work-this-way)
  - [Saving what you changed](#saving-what-you-changed)
  - [Handing control to the repo](#handing-control-to-the-repo)
  - [Good to know](#good-to-know)
- [Programs that keep their own state](#programs-that-keep-their-own-state)
- [Per-program reference](#per-program-reference)

---

## Wrapped programs

### What wrapping means

A **wrapped** program is the program *plus its config*, built into one
package. `alacritty` here is not really alacritty — it is a tiny script that
runs the real alacritty with `--config-file /nix/store/…/alacritty.toml`
every single time.

This is flakeos' replacement for home-manager, and it buys three things:

1. **Nothing is written into your home folder.** The config is in the repo and
   in the Nix store, read-only. There is no drift, no "where did that setting
   come from".
2. **The config is version-controlled with the program.** A rollback to an
   older generation rolls the config back with it.
3. **Every wrapped program is also a package of the flake**, so it runs
   anywhere Nix is installed, config and all:
   ```sh
   cd ~/flakeos
   ```
   ```sh
   nix run .#alacritty
   ```
   Which is also the fastest way to try a config change before installing it.

Wrapped here: **niri, noctalia, alacritty, zsh, git, btop, mpv, imv,
MangoHud, bat** (and Zed, in a special way — see below).

### The rules that follow from it

- **Config changes need a rebuild.** `nrs`. There is no reload.
- **`~/.config/<program>` is not read.** Editing it does nothing at all. This
  is the single most common "my change doesn't work" on this system.
- **Settings changed *inside* a wrapped program do not survive a restart.**
  Change btop's options in btop and they are gone next time, because its
  config is read-only in the store. Change them in
  `modules/programs/btop/btop.nix` instead.
- **`git config --global` cannot write.** Edit `modules/programs/git/gitconfig`.
- **A wrapped program's config is the same for every user** on the machine.
  Each user's *own* state (Firefox profile, Steam library) is still separate.

### The exceptions

**noctalia** is wrapped but keeps a GUI. It writes what you change in its
settings window to a file of its own that it reads *after* ours, so the window
genuinely works. Getting those changes into the repo is
[noctalia.md](noctalia.md#keeping-what-you-changed).

**Zed** cannot be pointed at a config file at all. So its wrapper links two
files into `~/.config/zed/` before every start:

- `global_settings.json` — our defaults, from `modules/programs/zed/settings.json`
- `themes/palette.json` — "Adwaita Dark (palette)", generated from the palette

Zed's own `settings.json` stays yours: changes you make inside Zed are saved
there and **win** over our defaults. So Zed is the one program where the GUI is
simply in charge, and the repo only provides the starting point.

---

## dconf: GTK apps with no config file

### How it works

Some programs have no config file whatsoever. Rnote, Shortwave, virt-manager
and the GTK file picker keep everything in **dconf**: a settings database at
`~/.config/dconf/user`. It is not a text file, it is not in the repo, and on a
fresh install it starts empty — so every pen, colour and preference you set up
is gone.

This config can put settings into dconf as well. They land in `/etc/dconf/db/`,
*underneath* your own copy:

| where | what it is |
|---|---|
| `~/.config/dconf/user` | what you changed in the program. **This one wins** |
| `/etc/dconf/db/…` | what this repo installs. Used until you change it |

So a saved setting is what the program **starts out** with, and changing it in
the program still works normally. `dconf-changes` is the bridge: it shows what
you changed and writes it into the repo.

The whole command, with rnote as the example:

```
dconf-changes                   which programs did I change something in?
dconf-changes rnote             show those changes
dconf-changes rnote --save      write them to modules/programs/rnote/dconf/rnote
dconf-changes rnote --all       also show keys the repo already sets
dconf-changes --help            the help text
```

### Does my program work this way?

There is no list to look up. Just try it: change something in the program,
close it, then:

```sh
dconf-changes
```

- **The program is in the list** → it uses dconf, carry on below.
- **Not in the list** → look for a config file instead:
  ```sh
  ls ~/.config
  ```
  A folder with the program's name means it writes a config file, and that is
  a different job — wrapping it, see
  [blueprints.md](blueprints.md#c-wrapped-by-hand). Nothing at all? Then it
  saves somewhere of its own, like Steam, Lutris and Firefox profiles, and
  those are not worth chasing.

### Saving what you changed

- **Set the program up** the way you like it, then **close it**.
- **See what you changed.** The name is its folder in `modules/programs/`:
  ```sh
  dconf-changes rnote
  ```
- **Write it into the repo:**
  ```sh
  dconf-changes rnote --save
  ```
  It goes to `modules/programs/rnote/dconf/rnote`.
- **Throw out what you don't want.** Window sizes and "last opened" paths end
  up in there too. Open the file:
  ```sh
  zeditor ~/flakeos/modules/programs/rnote/dconf/rnote
  ```
  **Deleting the line is not enough.** The setting is still in your own copy of
  dconf, so the next `--save` puts it straight back. Delete the line **and**
  write the key on the `# ignore:` line at the top of the file (several keys
  separated by spaces, or several `# ignore:` lines). That is how
  `rnote/dconf/rnote` keeps `window-width` and friends out for good.
- **New file? Tell git, look at it, rebuild:**
  ```sh
  cd ~/flakeos
  ```
  ```sh
  git add -A
  ```
  ```sh
  git diff HEAD
  ```
  ```sh
  nrs
  ```
- **Only for a program that has never had a `dconf/` folder:** the module has
  to load it. One line inside the `flake.nixosModules.<name> = { … }` block
  (`modules/programs/rnote/rnote.nix` already has it — copy from there):
  ```nix
  programs.dconf.profiles.user.databases = [{keyfiles = [./dconf];}];
  ```

### Handing control to the repo

After the rebuild the setting is in the repo **and** still in
`~/.config/dconf/user`. Nothing looks different — but editing the repo file by
hand now does nothing, because your own copy wins. To hand control over, close
the program and drop your copy:

```sh
dconf reset -f /com/github/flxzt/rnote/
```

`dconf-changes --save` prints the exact path to use. It clears *everything*
under that path that you did not save, which is the point, but check the saved
file first.

This is the same trap as skipping `--clear` with noctalia. Both tools print
the step; it is worth actually doing it.

### Good to know

- **The saved file is dconf's own format**, one line per setting, exactly what
  `dconf dump` prints. Nothing is translated, so nothing can be translated
  wrong — but some programs (rnote) squeeze all their settings onto one very
  long line. That is normal.
- **A key on an `# ignore:` line** is never saved and never shown by
  `dconf-changes <program>` either, so what you see is what you get. `--all`
  shows it anyway.
- **`--save` merges**: your comments and keys you saved earlier stay, only the
  keys you just changed are replaced. Saving twice in a row changes nothing.
- **Settings that already match the repo are left out**, so you only ever see
  what is actually new. `--all` shows them anyway.
- **`--all` cannot be combined with `--save`** — it would write the very keys
  an `# ignore:` line says to keep out. The tool refuses and says so.
- These settings are **for everyone on the machine**, like a wrapped config.
- **Want the repo to win always, GUI or not?** Add `lockAll = true;` next to
  `keyfiles`. The setting then cannot be changed in the program at all, so
  this is for things that must not drift, not for everyday use.

---

## Programs that keep their own state

Steam, Lutris, Prism Launcher, Firefox, Brave, RustDesk, Claude Code and Fresh
all keep their own state in your home folder: libraries, accounts, logins,
bookmarks, instance lists. None of it is in the repo, and that is deliberate —
it is data, not configuration, and some of it is secret.

What *is* in the repo for them is the part that can be declared:

- **Firefox**: extensions, telemetry off, dark theme, new-tab page, and the
  rest, as "policies" in `modules/programs/firefox/firefox.nix`. nixpkgs builds
  a wrapped Firefox from them — the same idea as our wrappers, done upstream.
- **Brave**: the same, as Chromium policies in
  `modules/programs/brave/brave.nix`. `brave://policy` in the browser shows
  which ones actually arrived.
- **Steam**: Proton-GE, 32-bit graphics, controller rules, firewall ports —
  see [gaming.md](gaming.md).

So after a reinstall you log back into Steam and Firefox, and everything
*around* them is already set up.

If you want a program's own state to survive a reinstall, the answer is a
backup, not the repo. On zeus, `/mnt/data` is not touched by an install.

---

## Per-program reference

| program | its settings are | change them in |
|---|---|---|
| niri | wrapped | `modules/programs/niri/config.kdl` |
| noctalia | wrapped + a GUI | its settings window, then `noctalia-changes --save` ([guide](noctalia.md)) |
| alacritty | wrapped | `modules/programs/alacritty/alacritty.toml` |
| zsh | wrapped | `modules/programs/zsh/zshrc` |
| git | wrapped | `modules/programs/git/gitconfig` |
| btop | wrapped | `modules/programs/btop/btop.nix` |
| mpv | wrapped | `modules/programs/mpv/mpv.conf` |
| imv | wrapped | `modules/programs/imv/imv.nix` |
| MangoHud | wrapped | `modules/programs/mangohud/MangoHud.conf` |
| bat | wrapped | `modules/programs/bat/bat.nix` |
| Zed | linked defaults, Zed's own file wins | `modules/programs/zed/settings.json`, or just inside Zed |
| Firefox | policies + your profile | `modules/programs/firefox/firefox.nix` |
| Brave | policies + your profile | `modules/programs/brave/brave.nix` |
| Thunar | xfconf + `/etc/xdg` | `modules/programs/thunar/thunar.nix` and `uca.xml` |
| rnote | dconf | `dconf-changes rnote --save` |
| Shortwave | dconf | `dconf-changes shortwave --save` |
| virt-manager | dconf | `dconf-changes virt-manager --save` |
| Autoclicker | its own `~/.config/autoclicker/settings.json` | the Autoclicker window |
| Steam, Lutris, Prism Launcher | their own state | in the program |
| colours, fonts, cursor, icons | the palette | `modules/system/theme/palette.nix` ([theming.md](theming.md)) |
