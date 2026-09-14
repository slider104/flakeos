# blueprints: adding things to flakeos

Templates for everything you might add: programs, system settings, bundles,
users and machines. **Nothing in here is used by the system**: `flake.nix`
only reads `modules/`. A blueprint only becomes real once you copy it into
`modules/`.

Every module in flakeos has the same shape, so instead of writing one from
scratch you copy the matching blueprint, rename it and fill it in. The
folders here mirror `modules/`, so each blueprint goes into the folder of
the same name.

How to read the guides below:
- Every command sits in its own box, so you can copy it. The line above
  says what it does.
- All commands run inside the repo. Open a terminal (Mod+Return) and go
  there first:
  ```sh
  cd ~/flakeos
  ```
- The guides use real names (`pinta`, `cava`, `bob`, …). For your own
  thing, replace that name **everywhere** in the commands.
- Files are edited in Zed. `zeditor <file>` opens one.

## Contents

- [How a module becomes part of the system](#how-a-module-becomes-part-of-the-system)
- [Which blueprint do I need?](#which-blueprint-do-i-need)
- [Where to list it: a bundle or a host?](#where-to-list-it-a-bundle-or-a-host)
- [Add a program](#add-a-program)
  - [Find it first](#find-it-first)
  - [Wrapped or not?](#wrapped-or-not)
  - [A. Plain (not wrapped)](#a-plain-not-wrapped)
  - [B. Wrapped with a ready-made module](#b-wrapped-with-a-ready-made-module)
  - [C. Wrapped by hand](#c-wrapped-by-hand)
  - [D. From another flake](#d-from-another-flake)
  - [Extras: default apps and palette colours](#extras-default-apps-and-palette-colours)
- [Add a system setting](#add-a-system-setting)
- [Add a bundle](#add-a-bundle)
- [Add a user](#add-a-user)
- [Add a host (a machine)](#add-a-host-a-machine)
- [Remove something](#remove-something)
- [When the rebuild complains](#when-the-rebuild-complains)

## How a module becomes part of the system

**The idea:** every `.nix` file in `modules/` *publishes* a module under a
name, e.g. `flake.nixosModules.pinta = …`. Publishing alone does nothing.
A module only ends up on a machine when something *lists* its name: a
bundle in `grouped/`, or a host in `hosts/`. It's a chain:

```
programs/pinta/pinta.nix   publishes "pinta"
grouped/desktop.nix        lists "pinta"      (publishes "desktop")
hosts/zeus/zeus.nix        lists "desktop"
                           → zeus gets pinta
```

So adding anything is always the same five steps:

1. **Copy** the blueprint into `modules/`.
2. **Rename**: the file names and every `example` inside become the real
   name. Files are named after what they are, never `default.nix`.
3. **Fill it in**: the actual setting, package or config.
4. **List it**: add the name to a bundle in `modules/grouped/` or to a host
   in `modules/hosts/<host>/<host>.nix`. (Hosts themselves are the
   exception: they are picked by hostname.)
5. **`git add -A`, then `nrs`**. The flake only sees files git knows about;
   a file that isn't added is silently missing.

The name you publish and the name you list must be exactly the same. The
`sed` commands below take care of that.

## Which blueprint do I need?

| I want to add… | blueprint | goes to |
|---|---|---|
| a program without config to manage (Steam, launchers, GUI apps with a settings dialog) | `programs/plain/` | `modules/programs/<name>/` |
| a program that has a ready-made wrapper module ([list](https://nix-community.github.io/nix-wrapper-modules/)) | `programs/wrapped/` | `modules/programs/<name>/` |
| a program with a config file, but no ready-made module | `programs/wrapped-custom/` | `modules/programs/<name>/` |
| a program that isn't in nixpkgs, from its own flake | `programs/from-flake/` | `modules/programs/<name>/` |
| a system setting / service / hardware support | `system/example.nix` | `modules/system/<topic>.nix` |
| a bundle of things (like `gaming`) | `grouped/example.nix` | `modules/grouped/<name>.nix` |
| a person | `users/example.nix` | `modules/users/<name>.nix` |
| a machine | `hosts/example/` | `modules/hosts/<name>/` |

## Where to list it: a bundle or a host?

**The idea:** a host doesn't list 40 programs one by one. It picks a few
*bundles* from `modules/grouped/`, and each bundle lists the programs and
settings that belong together. Change a bundle, and every host that picks
it gets the change.

| bundle | what's in it | picked by |
|---|---|---|
| `base` | boot, nix, network, locale, zsh, git, btop, fastfetch, bat, cli | zeus, hermes |
| `desktop` | login, polkit, xdg, audio, fonts, theme, niri, noctalia, alacritty, Firefox, Zed, fresh, nix-tools, Claude Code, Thunar, mpv, imv, Shortwave, Rnote, LibreOffice, RustDesk, Media Writer | zeus, hermes |
| `gaming` | Steam, GameMode, gamescope, MangoHud, Prism Launcher, Lutris | zeus |

Where does the new thing go?
- Useful on every machine, even without a screen (a terminal tool) →
  `grouped/base.nix`
- A desktop app or anything graphical → `grouped/desktop.nix`
- Game related → `grouped/gaming.nix`
- Only for one machine → straight into that host's file, like `openrgb` in
  `hosts/zeus/zeus.nix` or `bluetooth` in `hosts/hermes/hermes.nix`

Listing a name twice (in two bundles, or in a bundle and a host) is
harmless; it's still installed once.

---

## Add a program

### Find it first

- Search the package on https://search.nixos.org/packages. The name you
  need is the one after `pkgs.` (e.g. `pkgs.pinta` → `pinta`). Or in a
  terminal:
  ```sh
  nix search nixpkgs pinta
  ```
- Try it without installing anything. It's gone once you close it:
  ```sh
  nix run nixpkgs#pinta
  ```
- Does NixOS have a *module* for it? Search `programs.pinta` or
  `services.pinta` on https://search.nixos.org/options. A module sets up
  more than the package (Steam's adds 32-bit graphics and controller rules).
- Is there a ready-made *wrapper* module? Check the list on the left of
  https://nix-community.github.io/nix-wrapper-modules/.

### Wrapped or not?

**The idea:** wrapping bakes a program's config into the program itself
(see "Wrapping instead of home-manager" in the [main README](../README.md)).
That's only worth it, and only possible, when all three are true:

1. there is a config you want to manage in this repo,
2. the program can be *told* where its config is (a flag like
   `--config <file>` or an environment variable),
3. the program doesn't write to its config itself (a config in the store is
   read-only).

Go down this list and take the first match:

| question | yes → |
|---|---|
| Not in nixpkgs at all? | [D. From another flake](#d-from-another-flake) |
| Keeps its own settings or state (library, logins, a settings dialog), or has nothing to configure? | [A. Plain](#a-plain-not-wrapped) |
| Is there a ready-made wrapper module? | [B. Wrapped, ready-made](#b-wrapped-with-a-ready-made-module) |
| Does it take a config flag or environment variable? | [C. Wrapped by hand](#c-wrapped-by-hand) |
| None of the above | [A. Plain](#a-plain-not-wrapped) |

How the programs in this repo were decided:

| way | programs | why |
|---|---|---|
| B. wrapped, ready-made | niri, noctalia, alacritty, zsh, git, btop, mpv, imv | config lives here, module exists |
| C. wrapped by hand | mangohud, bat | no module, but an environment variable for the config |
| C. special case | Zed | can't be pointed at a file, so its wrapper links files into `~/.config/zed` before every start |
| A. plain, NixOS module | Firefox | nixpkgs itself builds a wrapped Firefox from `policies` |
| A. plain | Steam, Lutris, Prism Launcher | they keep their own state (library, accounts) |
| A. plain | Shortwave, Rnote, LibreOffice, RustDesk, Claude Code, fresh | same: stations, settings, IDs, logins are their own |
| A. plain | Media Writer, nix-tools, cli, fastfetch | nothing to configure |
| A. plain | Thunar | its settings live in xfconf (a database), not in a file |
| A. plain, NixOS module | GameMode, gamescope, OpenRGB | system services, need special permissions |

### A. Plain (not wrapped)

**The idea:** the program is simply installed, like on any Linux. It keeps
its settings in your home folder (`~/.config`, `~/.local/share`) and you
change them inside the program. There are two ways to install it:
- **the package only:** `environment.systemPackages = [pkgs.pinta];`
- **a NixOS module**, if one exists: `programs.steam.enable = true;` The
  module installs the package *and* sets up what the program needs around
  it (services, groups, firewall ports, udev rules).

**Where to look it up:** package names on
https://search.nixos.org/packages, modules on
https://search.nixos.org/options.
**Real ones in this repo:** `programs/lutris/` (package),
`programs/steam/` (module).

Example: the image editor **Pinta** (package only, NixOS has no module for it).

- Copy the blueprint as a new program folder:
  ```sh
  cp -r blueprints/programs/plain modules/programs/pinta
  ```
- Name the file after the program:
  ```sh
  mv modules/programs/pinta/example.nix modules/programs/pinta/pinta.nix
  ```
- Replace the placeholder `example` with the name:
  ```sh
  sed -i 's/example/pinta/g' modules/programs/pinta/pinta.nix
  ```
- Open it:
  ```sh
  zeditor modules/programs/pinta/pinta.nix
  ```
- The blueprint shows both ways. Pinta has no module, so delete the
  `programs.pinta.enable` line, remove the `#` in front of
  `environment.systemPackages`, and delete the `xdg.mime…` part (Pinta
  registers its file types itself). Keep the comment at the top if you
  like. What's left:
  ```nix
  {
    flake.nixosModules.pinta = {pkgs, ...}: {
      environment.systemPackages = [pkgs.pinta];
    };
  }
  ```
- List it in the desktop bundle:
  ```sh
  zeditor modules/grouped/desktop.nix
  ```
  Add a line `pinta` under `# programs/`.
- Let git (and the flake) see the new files:
  ```sh
  git add -A
  ```
- Rebuild:
  ```sh
  nrs
  ```
- Check: Mod+Space, type "pinta".

### B. Wrapped with a ready-made module

**The idea:** [nix-wrapper-modules](https://nix-community.github.io/nix-wrapper-modules/)
has modules for many programs. Such a module knows the program's config
format and its config flag. You give it the settings, it writes the config
file into the Nix store and builds a small start script that always runs
the program with that file. The `.install` part at the bottom of the file
puts this wrapped program on your system.

The settings can come in two ways:
- **a) as Nix**, in `settings = { … };`. The module turns them into the
  program's own format. Use this when you want [palette colours](#extras-default-apps-and-palette-colours).
  Real ones: `programs/imv/` (INI), `programs/alacritty/` (TOML file +
  palette colours merged in).
- **b) as the program's own config file** next to the `.nix` file. The
  option name depends on the module: `"config.kdl".path` (niri),
  `"mpv.conf".path` (mpv), `configFile.path` (git).

**Where to look it up:**
- the module's page, e.g.
  https://nix-community.github.io/nix-wrapper-modules/wrapperModules/cava.html,
  lists its options (`settings`, a file option, …)
- the keys *inside* `settings` are the program's own config keys: look
  them up in the program's documentation (the module page links it).

Example: **cava**, a music visualizer for the terminal.

- Copy the blueprint:
  ```sh
  cp -r blueprints/programs/wrapped modules/programs/cava
  ```
- Name the file after the program:
  ```sh
  mv modules/programs/cava/example.nix modules/programs/cava/cava.nix
  ```
- We use way a) (settings as Nix), so the example config file isn't needed:
  ```sh
  rm modules/programs/cava/example.conf
  ```
- Replace the placeholder:
  ```sh
  sed -i 's/example/cava/g' modules/programs/cava/cava.nix
  ```
- Open it:
  ```sh
  zeditor modules/programs/cava/cava.nix
  ```
- Fill in `settings`. cava's config is INI: `general.framerate` becomes
  `framerate` in the `[general]` section. `"blue"` is a terminal colour,
  and those come from the palette (via alacritty), so it matches the rest:
  ```nix
  settings = {
    general.framerate = 60;
    color.foreground = "blue";
  };
  ```
  Delete the commented way b) lines if you like.
- List it in the desktop bundle:
  ```sh
  zeditor modules/grouped/desktop.nix
  ```
  Add a line `cava` under `# programs/`.
- Let git see the new files:
  ```sh
  git add -A
  ```
- Try the wrapped program before rebuilding. Every wrapper is also a
  package of this flake (Ctrl+C quits):
  ```sh
  nix run .#cava
  ```
- Install it:
  ```sh
  nrs
  ```

### C. Wrapped by hand

**The idea:** there is no ready-made module, but the program can be told
where its config is, with a **flag** (`--config <file>`) or an
**environment variable** (`PROGRAM_CONFIG=<file>`). The generic module
(`wlib.modules.default`) builds the start script with exactly that flag or
variable. Your config file sits next to the `.nix` file, in the program's
own format.

It can't be wrapped when the program has neither, or when it writes to its
config itself (your changes inside the program would fail or vanish). Then
use [A. Plain](#a-plain-not-wrapped).

**Where to look it up:**
- the program's help: `<program> --help` or `man <program>`, search for
  "config"; or its website
- the generic module's options (`package`, `flags`, `env`, `runShell`):
  https://nix-community.github.io/nix-wrapper-modules/modules/default.html

**Real ones in this repo:** `programs/mangohud/` (variable + a config file
with palette colours added), `programs/bat/` (only a variable, no file).

Example: **ripgrep** (`rg`), a fast search through files. It reads a config
file only from the variable `RIPGREP_CONFIG_PATH`.

- Copy the blueprint:
  ```sh
  cp -r blueprints/programs/wrapped-custom modules/programs/ripgrep
  ```
- Name the file after the program:
  ```sh
  mv modules/programs/ripgrep/example.nix modules/programs/ripgrep/ripgrep.nix
  ```
- Name the config file the way the program's docs call it:
  ```sh
  mv modules/programs/ripgrep/example.conf modules/programs/ripgrep/ripgreprc
  ```
- Replace the placeholder:
  ```sh
  sed -i 's/example/ripgrep/g' modules/programs/ripgrep/ripgrep.nix
  ```
- Open it:
  ```sh
  zeditor modules/programs/ripgrep/ripgrep.nix
  ```
- ripgrep uses a variable, not a flag. Delete the `flags."--config" = …`
  line and replace the commented `env…` line with:
  ```nix
  env.RIPGREP_CONFIG_PATH = "${./ripgreprc}";
  ```
  `./ripgreprc` is the file next to this one; `"${…}"` turns it into its
  path in the Nix store (variables need text, not a file).
- Open the config file:
  ```sh
  zeditor modules/programs/ripgrep/ripgreprc
  ```
  Add one option per line: ignore upper/lower case unless you type
  uppercase, also search hidden files, but skip git's own folder:
  ```
  --smart-case
  --hidden
  --glob=!.git/*
  ```
- It's a terminal tool, useful everywhere, so list it in the base bundle:
  ```sh
  zeditor modules/grouped/base.nix
  ```
  Add a line `ripgrep` under `# programs/`.
- Let git see the new files:
  ```sh
  git add -A
  ```
- Install it:
  ```sh
  nrs
  ```
- Check that it reads the config (shows "arguments loaded from config file"):
  ```sh
  rg --debug hello 2>&1 | grep "config file"
  ```

### D. From another flake

**The idea:** some programs aren't in nixpkgs, but their authors publish a
flake. You add that flake as an **input** in `flake.nix`, next to nixpkgs.
Its version is pinned in `flake.lock` and updated with `nup`, like
everything else. Then you use its package (or its NixOS module) in a
normal module. Always check nixpkgs first: every input is one more thing to
keep updated.

**Where to look it up:** the project's README, usually a "Nix" or "NixOS"
section. It tells you the flake URL and whether it offers a package
(`packages.<system>.default`) or a NixOS module (`nixosModules.default`).

Example with placeholders: a program `myprog` from `github:someone/myprog`.
Replace both with the real ones.

- Copy the blueprint:
  ```sh
  cp -r blueprints/programs/from-flake modules/programs/myprog
  ```
- Name the file after the program:
  ```sh
  mv modules/programs/myprog/example.nix modules/programs/myprog/myprog.nix
  ```
- Replace the placeholder:
  ```sh
  sed -i 's/example/myprog/g' modules/programs/myprog/myprog.nix
  ```
- Add the input:
  ```sh
  zeditor flake.nix
  ```
  Inside `inputs = { … };` add (`follows` makes it use our nixpkgs
  instead of downloading its own copy; leave that line out if the
  project's README doesn't mention nixpkgs):
  ```nix
  myprog = {
    url = "github:someone/myprog";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```
- Open the module:
  ```sh
  zeditor modules/programs/myprog/myprog.nix
  ```
  It installs `packages.<system>.default` already. If the project offers a
  NixOS module instead, use the commented variant at the bottom.
- List it, e.g. in the desktop bundle:
  ```sh
  zeditor modules/grouped/desktop.nix
  ```
- Let git see the new files:
  ```sh
  git add -A
  ```
- Rebuild. The first time, Nix adds the new input to `flake.lock` by itself:
  ```sh
  nrs
  ```

### Extras: default apps and palette colours

**Default app for a file type.** Any program module can say which file
types it opens on double-click (examples: `programs/mpv/mpv.nix`,
`programs/imv/imv.nix`):

```nix
xdg.mime.defaultApplications = lib.genAttrs [
  "image/png"
  "image/jpeg"
] (_: "imv.desktop");
```

(`lib` must be in the module's first line: `{lib, ...}: {`.)

- The file type of a file:
  ```sh
  xdg-mime query filetype picture.png
  ```
- The `.desktop` names of all installed apps:
  ```sh
  ls /run/current-system/sw/share/applications/
  ```
- Who opens a type right now:
  ```sh
  xdg-mime query default image/png
  ```
- Watch out: some apps claim types by themselves. LibreOffice claims
  `text/plain`, which is why `programs/zed/zed.nix` sets it back to Zed.

**Palette colours.** Wrapped programs can use the palette: the wrapped
blueprint already has `theme = config.theme;` at the top, so `theme.bg`,
`theme.accent`, `theme.text`, `theme.normal.red`, `theme.font.mono`, … work
in `settings`. All names are in `modules/system/theme/palette.nix`. Some
programs want colours without the `#`; see `programs/imv/imv.nix` for the
`noHash` trick.

---

## Add a system setting

**The idea:** `modules/system/` holds settings of the operating system
itself, not tied to one program: services, hardware support, kernel
options. One topic per file, named after the topic (`audio.nix`,
`bluetooth.nix`). Anything you find on https://search.nixos.org/options
can go in there.

**Where to look it up:** https://search.nixos.org/options (search a word
like "printing"), and the [NixOS wiki](https://wiki.nixos.org) for longer
how-tos. **Real ones:** `system/audio.nix`, `system/bluetooth.nix`.

Example: **printing** (CUPS, the printer service).

- Copy the blueprint:
  ```sh
  cp blueprints/system/example.nix modules/system/printing.nix
  ```
- Replace the placeholder:
  ```sh
  sed -i 's/example/printing/g' modules/system/printing.nix
  ```
- Open it:
  ```sh
  zeditor modules/system/printing.nix
  ```
  The blueprint's `services.example.enable` became
  `services.printing.enable = true;`, which is already the right option.
  Delete the commented "Tools" lines.
- List it in the desktop bundle, under `# system/`:
  ```sh
  zeditor modules/grouped/desktop.nix
  ```
- Let git see the new file:
  ```sh
  git add -A
  ```
- Rebuild:
  ```sh
  nrs
  ```
- Check (q quits):
  ```sh
  systemctl status cups
  ```
  Printers are then added in Firefox at http://localhost:631.

## Add a bundle

**The idea:** a bundle is one name for a list of names. Make one when
several hosts should share the same set of things, or to switch a whole
group on and off with one line in a host (like `gaming`). A bundle can also
list other bundles.

**Real ones:** `grouped/desktop.nix`, `grouped/gaming.nix`.

Example: an **office** bundle with printing, LibreOffice and Rnote.

- Copy the blueprint:
  ```sh
  cp blueprints/grouped/example.nix modules/grouped/office.nix
  ```
- Replace the placeholder:
  ```sh
  sed -i 's/example/office/g' modules/grouped/office.nix
  ```
- Open it and put the names into the list (one per line):
  ```sh
  zeditor modules/grouped/office.nix
  ```
  ```nix
  imports = with self.nixosModules; [
    # system/
    printing

    # programs/
    libreoffice
    rnote
  ];
  ```
  (`printing` is the module from [Add a system setting](#add-a-system-setting).
  LibreOffice and Rnote are in `desktop` too; that's fine.)
- Let a host pick the bundle:
  ```sh
  zeditor modules/hosts/zeus/zeus.nix
  ```
  Add a line `office` below `gaming`.
- Let git see the new file:
  ```sh
  git add -A
  ```
- Rebuild:
  ```sh
  nrs
  ```

## Add a user

**The idea:** a user file is one account: login name, groups, shell and a
first password. Groups decide what the user may do: `wheel` = may use
`sudo` (an admin), `networkmanager` = may change Wi-Fi, `gamemode` = GameMode
without a password prompt. A host gets the user by listing the name.

Passwords are *not* in the repo: `initialPassword` is only used when the
account is created, then the user changes it with `passwd`, and NixOS keeps
that from then on. Wrapped programs (zsh, niri, …) look the same for every
user; each user's own app settings (Firefox profile, Steam) are separate.

**Real one:** `users/slider.nix`.

Example: a user **bob** (not an admin).

- Copy the blueprint:
  ```sh
  cp blueprints/users/example.nix modules/users/bob.nix
  ```
- Replace the placeholder (name, and the first password `bob`):
  ```sh
  sed -i 's/example/bob/g' modules/users/bob.nix
  ```
- Open it:
  ```sh
  zeditor modules/users/bob.nix
  ```
  Put the full name into `description`. Should bob be an admin? Remove the
  `#` in front of `"wheel"`.
- Give the user to a host:
  ```sh
  zeditor modules/hosts/zeus/zeus.nix
  ```
  Add a line `bob` below `slider`.
- Let git see the new file:
  ```sh
  git add -A
  ```
- Rebuild:
  ```sh
  nrs
  ```
- To log in as bob: log out (Mod+Ctrl+Shift+Q). On the text login screen,
  type `bob` and the password `bob`, then change it in a terminal:
  ```sh
  passwd
  ```

The automatic login after boot stays with the user in the host's
`initial_session.user` line.

## Add a host (a machine)

**The idea:** a machine is a folder `modules/hosts/<name>/` with three files:

| file | what's in it |
|---|---|
| `<name>.nix` | what the machine gets: its hardware + disk, bundles, single programs, users, the hostname, autologin, `stateVersion` |
| `hardware.nix` | kernel modules for the disk controller, USB and CPU. Comes from a hardware scan **on that machine** |
| `disko.nix` | which disk gets erased and installed to (by its permanent `/dev/disk/by-id/` name) |

`<name>.nix` publishes `flake.nixosConfigurations.<name>`, a complete
system. `nrs` builds the one whose name matches the hostname, so the
folder name, the `nixosConfigurations.<name>` and `networking.hostName` must
all be the same.

**Real ones:** `hosts/zeus/` (desktop: gaming, OpenRGB, a second drive) and
`hosts/hermes/` (laptop: Bluetooth, battery in the bar).

A new machine has to be installed anyway, and the
[installation guide](../modules/setup/README.md) creates the host on the
way (steps 3 to 5): copy this blueprint, rename, hardware scan, pick the
disk. After the install:

- Commit and push the new folder, so your other machines know it (see
  "Saving changes to GitHub" in the [main README](../README.md)).
- A laptop? Add `bluetooth` to the host's list, and look at
  `hosts/hermes/hermes.nix` for the battery and brightness widgets in the bar.
- `system.stateVersion` stays as it was at install time. Never change it,
  also not after updates: it only tells NixOS how old the machine's data is.

## Remove something

**The idea:** a module that nothing lists does nothing. So there are two
levels:

- **Take it off the machine, keep the file:** delete its name from the
  bundle or host, then `nrs`. Adding the line back later brings it back.
- **Delete it for good:** first make sure nothing lists it anymore. This
  shows every place the name appears:
  ```sh
  grep -rnw pinta modules
  ```
  Remove it from the lists, then delete the folder:
  ```sh
  rm -r modules/programs/pinta
  ```
  Tell git about the deletion:
  ```sh
  git add -A
  ```
  ```sh
  nrs
  ```

A removed program's own settings in your home folder (e.g.
`~/.config/Pinta`) stay. Delete them by hand if you want. A removed user's
home folder stays too.

## When the rebuild complains

Nothing changes on your system when a rebuild fails. The last lines of the
error say what's wrong, usually with a file and line number:

| error says | usually means |
|---|---|
| `undefined variable 'pinta'`, pointing at a list | the list has a name nothing publishes: a typo, or the new file isn't `git add`ed |
| `undefined variable 'pkgs'` (or `lib`) | the module's first line needs it: `{pkgs, ...}: {` or `{pkgs, lib, ...}: {` |
| ``The option `programs.pinta' does not exist`` | the option name is wrong, or NixOS has no module for it: use `environment.systemPackages` |
| `syntax error, unexpected …` | a missing `;`, `}` or `"` just before that line |
| `option … is already declared` | the same program is wrapped in two files |

`nck` checks the whole config without building anything.
