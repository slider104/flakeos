# Theming: one palette for everything

Everything on this system is one shade of dark, and it comes from one file:

```
modules/system/theme/palette.nix
```

Change a value in there, run `nrs`, and the terminal, the editor, the bar, the
window borders, the text console and the in-game overlay all follow. That is
the third of [the three ideas](../README.md#the-three-ideas).

## Contents

- [The two halves](#the-two-halves)
- [What's in the palette](#whats-in-the-palette)
- [Changing a colour](#changing-a-colour)
- [Fonts](#fonts)
- [Cursor and icons](#cursor-and-icons)
- [Who reads what](#who-reads-what)
- [Using the palette in a new program](#using-the-palette-in-a-new-program)
- [Going light, or another colour scheme](#going-light-or-another-colour-scheme)
- [Wallpapers](#wallpapers)

---

## The two halves

There are two theming systems on any Linux desktop, and this config lines them
up rather than trying to merge them:

| half | covers | set by |
|---|---|---|
| **GTK and Qt** | ordinary desktop apps: Thunar, rnote, Shortwave, virt-manager, LibreOffice, Prism Launcher, OpenRGB | the standard **adw-gtk3-dark** theme, in `modules/system/theme/theme.nix` |
| **the palette** | everything that isn't a GTK app: alacritty, niri, noctalia, Zed, MangoHud, imv, btop, the text console | `modules/system/theme/palette.nix` |

The trick is that the palette's values **are** GNOME's dark Adwaita colours —
the same ones adw-gtk3-dark paints with. So the wrapped programs end up the
same grey as the GTK app next to them, without either side knowing about the
other.

Your RGB lighting is deliberately *not* part of this. It keeps its own dim
cyan, set in `modules/programs/openrgb/openrgb.nix` — see
[hardware.md](hardware.md#rgb-lighting-zeus).

## What's in the palette

```sh
bat ~/flakeos/modules/system/theme/palette.nix
```

**The nine interface colours**, with the Adwaita name each one copies:

| name | is | used for |
|---|---|---|
| `bg` | `#1d1d20` | content background: terminal, editor |
| `surface` | `#2e2e32` | the bar, panels, title bars |
| `overlay` | `#36363a` | popups, hovered rows |
| `border` | `#434347` | borders, the inactive focus ring |
| `muted` | `#919193` | secondary text |
| `text` | `#ffffff` | normal text |
| `accent` | `#3584e4` | the focus ring, selections (GNOME blue) |
| `onAccent` | `#ffffff` | text drawn *on* the accent colour |
| `error` | `#ed333b` | errors (GNOME red) |

**The sixteen terminal colours**, as `normal.<colour>` and `bright.<colour>`
(black, red, green, yellow, blue, magenta, cyan, white). These are GNOME
Console's default palette. They are what alacritty paints with — and because
btop and bat are told to draw with "the terminal's colours", those two follow
automatically, for free.

**Plus** `font.sans`, `font.mono`, `font.size`, `cursor.name`, `cursor.size`
and `icons`.

## Changing a colour

Say you want a green accent instead of the GNOME blue.

- Open the palette:
  ```sh
  zeditor ~/flakeos/modules/system/theme/palette.nix
  ```
- Change one line:
  ```nix
  accent = "#2ec27e";
  ```
- Rebuild:
  ```sh
  nrs
  ```
- **Reopen the programs you want to see it in** — a running program keeps the
  config it started with. For the bar:
  ```sh
  pkill -f 'bin/noctalia$'
  ```
  ```sh
  niri msg action spawn -- noctalia
  ```

niri is the exception: it reloads its config after every rebuild, so window
borders change immediately.

What follows an `accent` change: niri's focus ring, noctalia's highlights,
alacritty's selection, Zed's theme, MangoHud's GPU readout. What doesn't: the
GTK apps, which get Adwaita's own blue from adw-gtk3-dark. Matching those
would mean a custom GTK theme, which is a bigger job than it sounds.

## Fonts

```nix
font = {
  sans = "Noto Sans";
  mono = "JetBrainsMono Nerd Font";
  size = 14;
};
```

- `sans` is the interface font: GTK apps, the bar.
- `mono` is the terminal, the editor and anything that lines up in columns.
- `size` is the base size GTK and the bar use.

**JetBrainsMono Nerd Font is a "Nerd Font"**, meaning it carries thousands of
extra icon glyphs. That is what draws the shell prompt's rounded pills and the
little icons in the bar. Swap the mono font for one without those glyphs and
you get boxes where the icons were. (The text console has no Nerd Font either,
which is why the prompt has a plain fallback version — see
[general.md](general.md#opening-one-and-what-the-prompt-tells-you).)

The installed fonts are in `modules/system/fonts.nix`. To add one, put its
package in `fonts.packages` there, rebuild, then name it in the palette. To
see what a font is actually called:

```sh
fc-list | grep -i jetbrains
```

## Cursor and icons

```nix
cursor = {
  name = "Bibata-Modern-Classic";
  size = 26;
};

icons = "Papirus-Dark";
```

Both packages are installed in `modules/system/theme/theme.nix`
(`bibata-cursors`, `papirus-icon-theme`). Changing to a different theme means
changing the package there **and** the name here — the name is the theme's
folder name, not the package name.

One oddity handled for you: `theme.nix` also installs a cursor theme literally
named "default" that inherits from yours. X11 programs that never get told
which theme to use fall back to that name — Steam's web view in particular,
which runs in Valve's own container and can't see `/etc`.

## Who reads what

| program | gets its colours from | how |
|---|---|---|
| GTK 3 / GTK 4 apps | adw-gtk3-dark | `/etc/xdg/gtk-*/settings.ini` + dconf |
| Qt apps | adwaita-dark | `qt.style` in `theme.nix` |
| Firefox, Electron apps | dconf's `color-scheme = prefer-dark` | that one key is what makes them go dark |
| alacritty | the palette | merged into its TOML at build time |
| niri | the palette | a generated `theme.kdl` that `config.kdl` includes |
| noctalia | the palette | a generated palette file in its config folder |
| Zed | the palette | a generated theme, "Adwaita Dark (palette)" |
| MangoHud | the palette | appended to `MangoHud.conf` at build time |
| imv | the palette | its settings, without the `#` (it wants bare hex) |
| btop, bat | **the terminal's** 16 colours | so they follow alacritty, which follows the palette |
| the text console (TTY) | the palette's 16 colours | `console.colors` in `theme.nix` |

That btop/bat row is the nicest part of the design: two programs that get
themed correctly without anyone writing a colour for them anywhere.

## Using the palette in a new program

Any module file can read the palette at the top level:

```nix
{config, ...}: let
  theme = config.theme;
in {
  # theme.bg, theme.accent, theme.text, theme.normal.red,
  # theme.bright.cyan, theme.font.mono, theme.cursor.size, …
}
```

The wrapped blueprint already has that line, so in a new wrapped program's
`settings` you can write `theme.accent` straight away. Some programs want hex
without the `#` — `modules/programs/imv/imv.nix` has the one-liner for that
(`noHash`).

This works because the palette is a **flake-level** option, not a NixOS one,
so wrapped packages can read it too — they are built outside any particular
machine's configuration.

Details and a worked example: [blueprints.md](blueprints.md#extras-default-apps-and-palette-colours).

## Going light, or another colour scheme

Doable, but it is more than the palette. You would need to:

1. Put light values in `palette.nix`.
2. Swap `adw-gtk3-dark` for `adw-gtk3` in `theme.nix`, and
   `gtk-application-prefer-dark-theme` / `color-scheme` to the light versions.
3. Change `qt.style` to `adwaita`.
4. Pick a light icon theme (`Papirus` rather than `Papirus-Dark`).

All four live in `palette.nix` and `theme.nix`, so it is one commit and a
rebuild — and a bad result is one `git checkout` away.

Dark Reader is installed in both browsers, so websites without a dark mode go
dark too. That is per-browser, in
`modules/programs/firefox/firefox.nix` and `brave.nix`.

## Wallpapers

Not part of the palette: wallpapers are picked with **Mod+W** and remembered
by noctalia. Adding one, and making them rotate automatically, is in
[noctalia.md](noctalia.md#wallpapers).
