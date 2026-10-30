# niri: the window manager

niri is what draws your windows and reads your keyboard. It works unlike
anything you have used before, which is worth ten minutes of reading once.

Everything here lives in **`modules/programs/niri/config.kdl`**. Change it,
`nrs`, and the running niri reloads it immediately â no logout needed, and
the key binds are live straight away.

## Contents

- [The idea: one long strip](#the-idea-one-long-strip)
- [The keys](#the-keys)
  - [The ones to learn first](#the-ones-to-learn-first)
  - [Apps](#apps)
  - [Moving around](#moving-around)
  - [Sizes](#sizes)
  - [Workspaces](#workspaces)
  - [Monitors](#monitors)
  - [Screenshots](#screenshots)
  - [Notifications and the bar](#notifications-and-the-bar)
  - [Media keys](#media-keys)
  - [Session](#session)
- [Floating windows and window rules](#floating-windows-and-window-rules)
- [Tabbed columns](#tabbed-columns)
- [X11 programs](#x11-programs)
- [Changing the config](#changing-the-config)
- [When niri misbehaves](#when-niri-misbehaves)

---

## The idea: one long strip

Most window managers divide your screen up. niri doesn't. It is a
**scrolling** window manager:

- Every new window opens as a **column** to the right of the current one.
- The columns form **one long horizontal strip**, wider than your monitor.
  Your screen is a window onto that strip, and you scroll it left and right.
- **Nothing shrinks when you open more windows.** Open a tenth window and the
  first nine keep exactly the size they had; they just move off-screen to the
  left. This is the whole point.
- A column can hold **several windows stacked vertically** â that is the only
  "splitting" there is.
- **Workspaces sit below each other**, not beside. Each workspace is its own
  strip. Page Up / Page Down walks through them.

So the mental model is: *left and right moves along the strip, up and down
moves within a column, Page Up / Page Down changes strip.*

Two keys make this click:

- **Mod+O** â overview: zooms out and shows every window on every workspace at
  once. The best way to see the shape of what you have open.
- **Mod+BackSpace** â the complete list of key binds, generated from the
  config itself, so it is never out of date. **If you remember one key,
  remember this one.**

(**Mod** is the Windows / Super key throughout.)

---

## The keys

### The ones to learn first

| key | does |
|---|---|
| **Mod+BackSpace** | show every key bind |
| **Mod+Space** | app launcher â type a few letters, Enter |
| **Mod+Return** | terminal |
| **Mod+Q** | close the window |
| **Mod+Left / Mod+Right** | move along the strip |
| **Mod+O** | overview |
| **Mod+Escape** | a game or VM swallowed your shortcuts? This gives them back |

### Apps

| key | opens |
|---|---|
| Mod+Return | terminal (alacritty) |
| Mod+Space | launcher |
| Mod+B | Firefox |
| Mod+Shift+B | Brave (the second browser, for sites that talk to hardware) |
| Mod+E | files (Thunar) |
| Mod+Z | Zed (the editor) |
| Mod+G | Steam |

### Moving around

| key | does |
|---|---|
| Mod+Left / Mod+Right | focus the column left / right |
| Mod+Up / Mod+Down | focus the window above / below, *inside* the column |
| Mod+Ctrl+arrows | move the focused column / window in that direction |
| Mod+Home / Mod+End | jump to the first / last column |
| Mod+Ctrl+Home / Mod+Ctrl+End | move this column to the very start / end |
| Mod+scroll wheel | scroll along the strip |
| Mod+Ctrl+scroll | drag the column along as you scroll |
| Mod+C | centre the focused column on screen |
| Mod+Ctrl+C | centre everything currently visible |
| Mod+Alt+Left / Mod+Alt+Right | pull the window *into* the neighbouring column, or push it *out* into its own |

That last one is the one people miss. `Mod+Alt+Right` on a window in a column
of its own merges it into the column to the right, stacking them. Press
`Mod+Alt+Left` to split it back out. That is how you build a column of two or
three windows.

### Sizes

| key | does |
|---|---|
| Mod+F | maximize the column to the full screen width (press again to go back) |
| Mod+Shift+F | real fullscreen (no bar) |
| Mod+Ctrl+F | expand the column into whatever empty space is next to it |
| Mod+Shift+R | cycle the column through the preset widths: 1/3, 1/2, 2/3 |
| Mod+KeypadPlus / Mod+KeypadMinus | column width Â±10% |
| Mod+Shift+KeypadPlus / Minus | window height Â±10%, inside a column |

You can also drag window edges with the mouse while holding **Mod**.

### Workspaces

Workspaces are stacked vertically and created as you need them.

| key | does |
|---|---|
| Mod+1 â¦ Mod+9 | go to workspace 1 â¦ 9 |
| Mod+Shift+1 â¦ 9 | send the **window** there and follow it |
| Mod+Ctrl+1 â¦ 9 | send the whole **column** there |
| Mod+Page_Up / Mod+Page_Down | the workspace above / below |
| Mod+Ctrl+Page_Up / Page_Down | take the column with you |
| Mod+Shift+Page_Up / Page_Down | move the whole workspace up / down in the stack |
| Mod+Shift+scroll | walk through workspaces with the wheel |

### Monitors

| key | does |
|---|---|
| Mod+Shift+Left / Right | focus the monitor left / right |
| Mod+Ctrl+Shift+arrows | move the column to the monitor in that direction |
| Mod+MouseBack / Mod+MouseForward | focus the left / right monitor with the mouse's side buttons |
| Mod+Ctrl+Shift+MouseBack / Forward | move the column there with the same buttons |
| Mod+Shift+Alt+L | switch the monitors off (they come back on any key press) |

niri detects monitors by itself, so `config.kdl` has no `output` block at all
right now. To see what it decided:

```sh
niri msg outputs
```

### Screenshots

| key | does |
|---|---|
| Mod+S | the focused **window** |
| Mod+Ctrl+S | the whole focused **monitor** |
| Mod+Shift+S | **select a region** with the mouse |

All three save into `~/Pictures/Screenshots` *and* put the image on the
clipboard, so you can paste it straight into a chat.

### Notifications and the bar

| key | does |
|---|---|
| Mod+N | notification history |
| Mod+Shift+N | dismiss the popups currently on screen |
| Mod+Ctrl+N | empty the history |
| Mod+Comma | noctalia's settings window |
| Mod+W | pick a wallpaper |

These are noctalia, not niri â see [noctalia.md](noctalia.md).

### Media keys

The keys on a media keyboard work as you'd expect, and noctalia shows a
little on-screen display for volume and brightness.

| key | does |
|---|---|
| volume up / down / mute | the default output. Volume is capped at 100% |
| mic mute | the default input |
| play / pause / stop / next / previous | whatever is playing (via `playerctl`) |
| Shift + next / previous | seek Â±10 seconds |
| brightness up / down | screen brightness (laptop) |

These keep working while the screen is locked.

### Session

| key | does |
|---|---|
| Mod+Alt+L | session menu: lock, suspend, reboot, power off |
| Mod+Ctrl+Shift+Q | log out of niri (you land on the text login screen) |
| Mod+Escape | toggle the shortcut inhibitor â see below |

**Mod+Escape is the escape hatch worth remembering.** Some programs ask to
receive *all* keys, including Mod ones â games, and virtual machine windows.
When one does, your shortcuts stop working and the machine feels possessed.
Mod+Escape always works (it is marked `allow-inhibiting=false`) and hands the
shortcuts back.

---

## Floating windows and window rules

Most windows tile, i.e. open as a new column. niri floats a window by itself
when the program declares it a dialog or says it cannot be resized. Anything
else you want floating is a **window rule**.

By hand, right now:

- **Mod+A** â make the focused window float, or tile it again.
- **Mod+Ctrl+A** â jump between the floating windows and the tiled ones.

Permanently, in `config.kdl`. A rule needs the window's **app ID**, which is
rarely the program's name, so ask niri while the window is open:

```sh
niri msg windows
```

That lists every open window with its app ID, its title, and whether it
floats. Then add a rule in the `window-rule` section of `config.kdl`:

```kdl
window-rule {
    match app-id=r#"^org\.flakeos\.Autoclicker$"#
    open-floating true
}
```

- `open-floating false` does the opposite: it keeps a window **tiled** that
  niri would have floated on its own.
- `r#"â¦"#` is a raw string, so the backslashes in the pattern are taken
  literally. `^` and `$` mean "the whole app ID, exactly".
- Rules can do much more than floating â default column width, opacity,
  which workspace a program opens on, blocking screencast of a window. The
  full list is in niri's own documentation:
  https://github.com/YaLTeR/niri/wiki/Configuration:-Window-Rules

## Tabbed columns

**Mod+T** turns the focused column into a **tab bar**: the stacked windows
become tabs and only one is shown at a time. Press it again to go back to the
stack. Useful for a column of five terminals you don't want to be three
pixels tall.

## X11 programs

niri is Wayland-only. Programs that only speak X11 â Steam, some games, older
tools â run through **xwayland-satellite**, which niri starts on demand.
Mostly you never notice.

Two things that leak through:

- **The clipboard.** XWayland has its own clipboard, separate from niri's.
  This config runs a small bridge (`niri-clipboard-bridge`, in
  `programs/niri/niri.nix`) that mirrors the two in both directions, so copy
  and paste works between X11 and Wayland programs â and in and out of a
  virtual machine, which goes through XWayland on both sides. Text only, no
  images.
- **Electron apps** (Zed, Brave, VS Code) are told to run as native Wayland
  apps instead of X11, via `NIXOS_OZONE_WL=1`. That is why they look sharp
  and scale properly.

## Changing the config

```sh
zeditor ~/flakeos/modules/programs/niri/config.kdl
```
```sh
nrs
```

The file is KDL, a config format a bit like a cross between JSON and a shell
script. The sections you are most likely to touch:

| section | holds |
|---|---|
| `input` | keyboard layout (`layout "de"`), repeat rate, mouse and touchpad settings, focus-follows-mouse |
| `output` | per-monitor resolution, refresh rate, scale and position. Not in the file yet — add one only if auto-detection gets it wrong |
| `layout` | gaps, column widths, the preset widths Mod+Shift+R cycles, border and focus ring |
| `binds` | every key bind |
| `window-rule` | per-window behaviour, see above |
| `spawn-at-startup` | what starts with the session (noctalia, the clipboard bridge) |

Notes:

- **Every bind has a `hotkey-overlay-title`.** That text is what Mod+BackSpace
  shows. Add one when you add a bind, or your new key is invisible in the
  overlay.
- **Colours are not in this file.** The focus ring, background and cursor come
  from the palette, injected as a generated `theme.kdl` that `config.kdl`
  includes. See [theming.md](theming.md).
- **The keyboard layout is set twice** â here for the desktop, and in
  `modules/system/locale.nix` for the text console. They are separate systems;
  changing one does not change the other.
- The config is **checked while the system is built** (`niri validate`), so a
  broken config fails the rebuild instead of giving you a desktop that won't
  start.
- Try a change before installing it (Ctrl+C or Mod+Ctrl+Shift+Q to leave the
  nested session):
  ```sh
  cd ~/flakeos
  ```
  ```sh
  nix run .#niri
  ```

## When niri misbehaves

- **Ask niri what it thinks is going on.** `niri msg` is the whole interface:
  ```sh
  niri msg windows
  ```
  ```sh
  niri msg outputs
  ```
  ```sh
  niri msg workspaces
  ```
  ```sh
  niri msg focused-window
  ```
- **Do something from the command line** (handy in scripts, or when a key
  bind isn't working):
  ```sh
  niri msg action spawn -- noctalia
  ```
  ```sh
  niri msg action toggle-overview
  ```
  `niri msg action --help` lists every action, which is also the list of
  things you can bind a key to.
- **Read its log.** niri is started by your *session*, so it needs `--user`:
  ```sh
  journalctl --user -u niri -b -e
  ```
- **Shortcuts dead?** Mod+Escape.
- **Session completely wedged?** Mod+Ctrl+Shift+Q logs out to the text login
  screen. If even that is gone, Ctrl+Alt+F2 gives you a text console you can
  log into and look around from â see
  [troubleshoot.md](troubleshoot.md#the-desktop-doesnt-start).
