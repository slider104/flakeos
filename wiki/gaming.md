# Gaming

Everything gaming-related is one bundle: `modules/grouped/gaming.nix`. zeus
has it; hermes doesn't (it's a laptop). Adding it to a machine is one line in
`modules/hosts/<host>/<host>.nix` and a rebuild.

What's in it: **Steam** with Proton-GE, **GameMode**, **gamescope**,
**MangoHud**, **Lutris** and **Prism Launcher**.

## Contents

- [Steam](#steam)
  - [Proton: running Windows games](#proton-running-windows-games)
  - [Launch options: the three helpers](#launch-options-the-three-helpers)
  - [Controllers](#controllers)
  - [Remote Play and the local network](#remote-play-and-the-local-network)
- [MangoHud: the overlay](#mangohud-the-overlay)
- [GameMode](#gamemode)
- [gamescope](#gamescope)
- [Lutris: everything that isn't Steam](#lutris-everything-that-isnt-steam)
- [Prism Launcher: Minecraft](#prism-launcher-minecraft)
- [A game you just downloaded](#a-game-you-just-downloaded)
- [Performance notes](#performance-notes)
- [When a game misbehaves](#when-a-game-misbehaves)

---

## Steam

**Mod+G** starts it, or "Steam" in the launcher.

- **The very first start downloads ~500 MB of updates** and looks completely
  stuck. It isn't. Wait.
- Steam is **not** wrapped — it manages its own library, accounts and settings
  in `~/.steam` and `~/.local/share/Steam`, and none of that is in the repo.
  After a reinstall you log in again and re-download.
- Your games live wherever Steam's library points. On zeus, putting the
  library on `/mnt/data` means a reinstall doesn't cost you the downloads.

What the repo does set up for you (`modules/programs/steam/steam.nix`), all of
which other distros make you do by hand: 32-bit graphics libraries, controller
udev rules, Proton-GE, the firewall ports for Remote Play, and two fixes
specific to running Steam under niri (see
[When a game misbehaves](#when-a-game-misbehaves)).

### Proton: running Windows games

Proton is the compatibility layer that runs Windows games on Linux. Most games
work; some work better with a different Proton version.

**Steam → right-click a game → Properties → Compatibility → Force the use of a
specific Steam Play compatibility tool.**

| pick | when |
|---|---|
| nothing (leave it off) | the default. Steam picks for you, and for a game with a "Verified"/"Playable" badge that is usually right |
| **Proton-GE** | the community build, installed by this config. More media codecs and more fixes than Valve's. **The one to try first when a game misbehaves** |
| Proton Experimental | Valve's bleeding edge. Sometimes fixes a brand-new game |
| an older Proton (8, 7, …) | an old game that regressed |

Changing the Proton version makes the game rebuild its prefix (its fake
Windows installation) on the next start, which takes a minute. That is normal.

**Is this game going to work at all?** https://www.protondb.com — search the
game, read the top reports. They usually name the exact launch options needed,
which you paste into the box below.

### Launch options: the three helpers

**Steam → right-click a game → Properties → General → Launch Options.**
`%command%` is where Steam substitutes the game itself.

| launch options | does |
|---|---|
| `gamemoderun %command%` | GameMode: puts the CPU and GPU in performance mode while the game runs |
| `mangohud %command%` | the overlay: FPS, temperatures, load. Toggle with **Right Shift + F12** |
| `gamescope -W 2560 -H 1440 -f -- %command%` | runs the game in its own tiny compositor: fixed resolution, upscaling, frame limit |

They combine, left to right:

```
gamemoderun mangohud %command%
```

```
gamemoderun mangohud gamescope -W 2560 -H 1440 -f -- %command%
```

Note the `--` before `%command%` in the gamescope ones: it separates
gamescope's own options from the game's.

Other things that go in the same box, from protondb reports:

| option | does |
|---|---|
| `PROTON_LOG=1 %command%` | writes a log to `~/steam-<appid>.log`. **The first thing to do for a game that won't start** |
| `PROTON_USE_WINED3D=1 %command%` | fall back to OpenGL instead of Vulkan. Old games, rarely |
| `WINEDLLOVERRIDES="..." %command%` | what protondb tells you to paste for a specific game |
| `DXVK_HUD=fps %command%` | a minimal FPS counter, if you don't want MangoHud |

### Controllers

The udev rules come with Steam's NixOS module, so controllers work without
anything extra: Xbox (wired and wireless adapter), PlayStation, Switch Pro and
most third-party pads. Plug it in, or pair it over Bluetooth from noctalia's
control center.

**Steam → Settings → Controller** is where the configuration lives. Steam
Input can remap anything, including making a controller act as a keyboard and
mouse for a game that has no controller support.

One niri-specific detail, already handled: Steam Input's keyboard and mouse
emulation is written against an old X11 extension whose events would never
reach Wayland apps. This config enables `extest`, which turns them into a real
virtual input device the compositor picks up like any other mouse. So
"trackpad as mouse" and "button bound to a key" actually work. You will see
`cannot preload` messages about a 32-bit library in Steam's output — harmless.

### Remote Play and the local network

Both have their firewall ports opened already:

- **Remote Play** — stream a game to another PC, a phone or a Steam Deck.
- **Local network game transfers** — install a game from another PC on your
  network instead of downloading it again.

Nothing to configure; they just appear in Steam's settings.

---

## MangoHud: the overlay

The FPS and temperature overlay, usable on *any* program, not just Steam games.

- In Steam: `mangohud %command%` in the launch options.
- Anywhere else, from a terminal:
  ```sh
  mangohud lutris
  ```
  ```sh
  mangohud %any-program%
  ```
- **Right Shift + F12** toggles it on and off while the game runs.

What it shows is in `modules/programs/mangohud/MangoHud.conf`, and its colours
come from the palette, so it matches the rest of the system. MangoHud is
**wrapped**: edit that file, `nrs`, restart the game. Editing
`~/.config/MangoHud/` does nothing.

Useful keys in `MangoHud.conf`: `fps_limit`, `gpu_temp`, `cpu_temp`,
`frame_timing`, `position`, `font_size`. The full list is
`man mangohud` or https://github.com/flightlessmango/MangoHud.

## GameMode

A small daemon that switches the CPU governor to performance, bumps the GPU's
power profile and raises the game's scheduling priority — for as long as the
game runs, and then puts everything back.

- Steam: `gamemoderun %command%`.
- Elsewhere:
  ```sh
  gamemoderun ./somegame
  ```
- Is it active?
  ```sh
  gamemoded -s
  ```

Your user is in the `gamemode` group (its file in `modules/users/`), so it can
change the CPU governor **without a password prompt**. Without that group you
would get a polkit dialog in the middle of launching a game.

Worth it? On a desktop that is already on a performance profile, the gain is
small. On a laptop, or anything with aggressive power saving, it is real.

## gamescope

gamescope runs the game inside its own micro-compositor. The game thinks it
has a monitor to itself, which solves a specific family of problems:

| problem | gamescope option |
|---|---|
| the game insists on the wrong resolution | `-W 2560 -H 1440` (what the game is told it has) |
| the game won't go fullscreen properly under niri | `-f` |
| you want to render lower and upscale, for performance | `-w 1920 -h 1080 -W 2560 -H 1440 -U` (`-U` = FSR upscaling) |
| the game runs too fast and heats the room | `-r 120` (frame limit) |
| alt-tabbing out of the game breaks it | run it in gamescope; the game never loses its "monitor" |

Lowercase `-w`/`-h` is the internal render size; uppercase `-W`/`-H` is the
output size. Full list:

```sh
gamescope --help
```

Don't use it by default — it is a layer, and a layer can add a frame of
latency. Reach for it when a game has one of the problems above.

## Lutris: everything that isn't Steam

Lutris manages games that don't come from Steam: **GOG**, **Battle.net**,
**Epic**, emulators, old Windows installers, standalone executables.

- Start it from the launcher, or `lutris` in a terminal.
- It has installer scripts for most big launchers — search the game or
  launcher inside Lutris and it does the Wine setup for you.
- Its runners, prefixes and settings live in `~/.local/share/lutris` and
  `~/.config/lutris`. Not in the repo; it's state.
- To get the overlay or GameMode on a Lutris game, Lutris has its own
  checkboxes for both in the game's configuration — or start Lutris itself
  under them:
  ```sh
  gamemoderun mangohud lutris
  ```

## Prism Launcher: Minecraft

- Start it from the launcher.
- It ships the Java versions Minecraft needs, so there is nothing to install.
- Accounts, instances and mods live in `~/.local/share/PrismLauncher`.
- Instances are self-contained: one per modpack, no interference.

## A game you just downloaded

An itch.io build, a GOG offline installer, a random Linux binary. These are
built for ordinary distributions, so on NixOS they don't just run — see
[Running a program you downloaded](general.md#running-a-program-you-downloaded)
for the background.

Try in this order:

```sh
chmod +x ./thegame
```
```sh
./thegame
```

Most 64-bit Linux games work straight away, because `nix-ld` provides the
loader and the library pool they expect (`modules/system/nix-ld.nix` lists
them: graphics, sound, SDL, GTK, Electron).

If it complains about a missing file or library:

```sh
steam-run ./thegame
```

`steam-run` gives the program a complete fake ordinary-Linux filesystem to
live in. This is also the answer for **32-bit** games, which nix-ld does not
cover.

A Windows game with no Steam entry? Add it to Steam as a non-Steam game
(**Games → Add a Non-Steam Game**), then force Proton-GE on it in its
Properties. That gets you Proton, the overlay and the launch-options box for
free.

## Performance notes

Things this config already does, so you don't go looking for them:

- **Split lock mitigation is off** (`modules/grouped/gaming.nix`). Some games
  and Steam itself do "split lock" memory operations, which the kernel
  normally punishes by pausing the thread briefly — a real source of stutter.
  SteamOS turns it off; so do we. The "split lock detection" lines in the
  kernel log are just a warning and stay.
- **zram instead of a swap partition** (`modules/system/boot.nix`), tuned for
  it (`swappiness 180`, `page-cluster 0`). Compressed swap in RAM is fast
  enough that swapping idle pages out beats throwing away the file cache.
- **The latest kernel**, not the LTS one, so new hardware and new Mesa
  features are available.
- **32-bit graphics libraries** come with Steam's module, which is what old
  games and some Proton components need.
- **Proton-GE** is installed, not just available.

## When a game misbehaves

**Mod+Escape first.** If the game grabbed all your keyboard shortcuts and you
can't get out, that gives them back.

Then, roughly in order of how often it's the answer:

1. **Force Proton-GE** in the game's Compatibility settings, and restart it.
2. **Check protondb** (https://www.protondb.com) for that exact game. The top
   reports usually name the launch option that fixes it.
3. **Get a log:** put `PROTON_LOG=1 %command%` in the launch options, run the
   game, then read `~/steam-*.log`. Search it for `err:` lines.
4. **Try it in gamescope** if the problem is resolution, fullscreen or
   alt-tab.
5. **Check the driver is actually being used:**
   ```sh
   vulkaninfo --summary
   ```
   It should name your graphics card. `llvmpipe` means the driver didn't load
   and the CPU is drawing everything.
6. **Watch what the game prints.** Start Steam from a terminal and the game's
   own output lands there:
   ```sh
   steam
   ```

### Two niri-specific things, already fixed

Worth knowing they exist, in case they ever come back after an update:

- **Mod+G looked like a dead key.** Steam's launcher decides "Steam is already
  running" purely from whether it can open a leftover pipe file in your home
  folder — and that file survives reboots. So a press would silently hand off
  to a Steam that wasn't there and exit. `steam-launch` (what Mod+G actually
  runs) checks properly first and clears the stale pipe.
- **Steam's menus flickered open and shut.** The X11 bridge was giving
  keyboard focus to Steam's pop-up menus, Steam saw its main window lose
  focus, and closed the menu. Fixed upstream; this config builds the fixed
  commit until a release carries it. The comment in
  `modules/programs/niri/niri.nix` says when that override can be deleted.
