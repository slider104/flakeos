# Virtual machines

A virtual machine is a whole second computer running in a window on this one.
You install an operating system into it, use it, break it, throw it away — the
machine you are sitting at is never touched. Good for trying another Linux,
keeping a Windows around for one program, or testing a flakeos change before
it goes on real hardware.

## Contents

- [How it works](#how-it-works)
- [What you need](#what-you-need)
- [1. Create the machine](#1-create-the-machine)
- [2. The settings that matter](#2-the-settings-that-matter)
- [3. Living in the window](#3-living-in-the-window)
- [4. The other half: inside the guest](#4-the-other-half-inside-the-guest)
- [5. Your own resolution](#5-your-own-resolution)
- [6. The clipboard](#6-the-clipboard)
- [Handy extras](#handy-extras)
- [Testing a flakeos change in a VM](#testing-a-flakeos-change-in-a-vm)
- [When something goes wrong](#when-something-goes-wrong)

---

## How it works

Three pieces do the work:

| piece | what it does |
|---|---|
| **KVM** | the part in the Linux kernel. It hands the guest *real* CPU cores instead of imitating them — that is why a machine can feel almost like a normal PC |
| **QEMU** | builds the rest of the PC around those cores: disk, network, screen, sound |
| **libvirt** | remembers the machines and starts them |

The window you click in is **Virtual Machine Manager**, in the launcher
(Mod+Space, type "virtual").

Everything the usual guides make you do by hand — install the packages, switch
the service on, put your user in the `libvirtd` group, start the `default`
network — is already done by `modules/grouped/vm.nix`. There is nothing to set
up; open the window and create a machine.

The machines and their disks live in `/var/lib/libvirt/images`, **not** in this
repo. They survive rebuilds and updates. Deleting a machine in the manager
deletes them.

The repo files behind all this:

| file | what it does |
|---|---|
| `modules/system/libvirt.nix` | the machinery: KVM, QEMU, libvirtd, the NAT network, USB redirection, the emulated TPM |
| `modules/programs/virt-manager/virt-manager.nix` | the window, and what a new machine starts out with |
| `modules/programs/niri/niri.nix` | the clipboard bridge (see [The clipboard](#6-the-clipboard)) |

## What you need

- **The `vm` bundle on your machine.** zeus has it. If a host doesn't, add
  `vm` to the list in `modules/hosts/<host>/<host>.nix` and `nrs`.
- **An ISO** of the system you want to install. Download it first; the wizard
  asks for the file.
- **Space**: 30–60 GB for a desktop guest. The disk file only grows to what is
  really used (that is what `qcow2` means).
- **Enough RAM to share.** A desktop guest wants 8–16 GB while it runs.

## 1. Create the machine

**File → New Virtual Machine → Local install media**, pick the ISO, give the
machine memory and CPUs, and on the last page tick **Customize configuration
before install**.

That last tick is the important one: it opens the machine's settings *before*
it boots for the first time, and a few of them cannot be changed sensibly
afterwards.

## 2. The settings that matter

Some of these are already the default, because
`modules/programs/virt-manager/virt-manager.nix` sets them for the wizard.
They are listed anyway so you know what you are looking at.

| page | set | why |
|---|---|---|
| Memory | about a quarter of this machine's RAM (`16384` MiB on a 64 GB machine) | enough for a full desktop guest, with plenty left for the host |
| CPUs → vCPU allocation | about half the threads (`16` of 32) | the guest gets real cores, the host keeps enough to stay responsive |
| CPUs → Topology | 1 socket, half the vCPUs as cores, 2 threads (16 vCPUs → 1 × 8 × 2) | the guest sees one normal CPU with hyperthreading instead of a pile of single-core sockets — Windows and most schedulers handle that much better |
| CPUs → Model | `host-passthrough` | **already set.** The guest sees this machine's real CPU with all its instructions. The biggest single speed setting. The price: the machine expects a comparable CPU if you ever copy it to another PC |
| Overview → Firmware | `UEFI` | **already set.** Guests boot like a modern PC. Windows 11 needs it |
| Overview → Chipset | `Q35` | the modern virtual mainboard (PCIe, UEFI). The wizard picks it for anything recent |
| Disk 1 → Disk bus | `VirtIO` | the guest talks to the disk directly instead of through an emulated SATA controller — the biggest difference in disk speed |
| Disk 1 → Advanced → Discard mode | `unmap` | deleting files in the guest gives the space back on the host |
| NIC → Device model | `virtio` | the same idea for the network card |
| Display Spice | keep Spice; *Listen type* **None** and tick **OpenGL**, render node = the GPU your monitors are on | clipboard, automatic resolution, USB devices. The dropdown names every GPU — pick the one drawing your desktop, not the CPU's built-in one |
| Video | `Virtio`, and tick **3D acceleration** for a Linux guest | lets the guest use the real GPU for its desktop. **Linux only**: Windows has no driver for it, leave both off there |
| TPM (Add Hardware → TPM) | emulated TPM 2.0, **only for Windows 11** | Windows 11 refuses to install without one. The host side is already set up (`swtpm`) |

Then **Begin Installation**, and install the system in the window like on a
real PC. Memory, CPUs and disk size can all be changed later in the machine's
settings, while it is shut down.

## 3. Living in the window

- **The pointer is released** from the machine's window with **Ctrl + Alt**.
- **View → Fullscreen** shows the guest 1:1. The toolbar slides back in when
  you push the mouse to the top edge.
- **View → Scale display → Only when fullscreen** is the sane setting: in a
  window the picture is scaled to fit, in fullscreen it is exact.
- **The machine keeps running when you close its window.** The manager window
  lists it; double-click to look again. To actually stop it, shut it down from
  inside the guest or use the manager's power button.
- **Mod+Escape** if the VM window has swallowed your niri shortcuts.
- `virt-viewer` is installed too: it opens just a machine's screen, without
  the manager window around it.

## 4. The other half: inside the guest

The last bit of "feels like hardware" happens *inside* the machine, and it is
the step people forget.

### Linux guest

Install its `spice-vdagent` and `qemu-guest-agent` packages. On a NixOS guest,
two lines:

```nix
services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;
```

- **`qemu-guest-agent`** is what lets the host ask the guest things (its IP,
  its screen size) and shut it down properly instead of pulling the plug.
- **`spice-vdagent`** is the clipboard and the automatic resolution. On a niri
  guest it needs two more lines — see [The clipboard](#6-the-clipboard).

### Windows guest

Windows has no VirtIO drivers, so its installer shows **no disk at all**. Get
the driver ISO:

```sh
nix build --no-link --print-out-paths nixpkgs#virtio-win.src
```

Attach the path it prints as a second CD-ROM (**Add Hardware → Storage →
Device type CDROM**), and during the Windows setup click *Load driver* → the
`viostor` folder. After the install, run `virtio-win-guest-tools.exe` from the
same ISO for everything else (network, display, clipboard).

## 5. Your own resolution

A virtual graphics card has no monitor to ask, so QEMU invents one: a fixed
list of classic sizes, none of them yours. The guest picks the best it is
offered — often 1280x800 — and a guest agent can only resize it on X11 or
GNOME, not on niri. So tell the card its size:

1. **Shut the machine down** (the setting is read at boot).
2. Its window → the **i** button (virtual hardware details) → **Video
   Virtio** → the **XML** tab. (That tab is visible because
   `xmleditor-enabled` is set for you.)
3. Add the `resolution` line, with your monitor's size:

   ```xml
   <model type='virtio' heads='1' primary='yes'>
     <acceleration accel3d='yes'/>
     <resolution x='2560' y='1440'/>
   </model>
   ```

4. **Apply**, start the machine. The guest now offers that mode and picks it
   by itself. **View → Fullscreen** then shows it 1:1.

## 6. The clipboard

`spice-vdagent` carries the clipboard, and it is an X11 program: on both
machines the clipboard has to pass through XWayland. A GNOME or KDE guest
hides all of this — they start the agent themselves and their compositors
carry the X clipboard across. With niri on both sides, three pieces are
missing:

| where | what is missing | fixed by |
|---|---|---|
| guest | nothing starts the agent's client | `spawn-at-startup "spice-vdagent"` in the guest's niri config |
| both | XWayland's clipboard and niri's are separate, and the X11 bridge does not carry anything between them | `niri-clipboard-bridge`, in `modules/programs/niri/niri.nix`, spawned at startup |
| host | as a Wayland client, virt-manager never notices that something *else* on this machine copied — so the clipboard stops travelling the moment the guest copies | virt-manager is run on XWayland, in `modules/programs/virt-manager/virt-manager.nix` |

**Both host halves are already done by this repo.** A NixOS guest needs the
agent, the same bridge (copy the `niri-clipboard-bridge` package out of
`programs/niri/niri.nix`), and two lines in its niri config:

```nix
services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;
environment.systemPackages = [pkgs.spice-vdagent]; # + niri-clipboard-bridge
```

```kdl
spawn-at-startup "spice-vdagent"
spawn-at-startup "niri-clipboard-bridge"
```

`spice-vdagent` has to come from niri's `spawn-at-startup`, **not** from a
systemd user service: `spice-vdagentd` only accepts a client that belongs to
the active login session and drops every other one. Text only, no images.

## Handy extras

- **A shared folder:** Add Hardware → Filesystem, source `/mnt/data`, target
  tag `data`. In a Linux guest:
  ```sh
  mount -t virtiofs data /mnt/data
  ```
- **A USB stick or controller in the guest:** Virtual Machine → Redirect USB
  device, while the machine runs.
- **Snapshots:** the camera icon in the machine's window. Takes a picture of
  the whole machine that you can jump back to — this is what `qcow2` disks are
  for, and it makes a VM the ideal place to try something destructive.
- **Clone a machine:** right-click it in the manager → Clone.
- **Every knob libvirt has:** the XML tab in the machine's details.
- **From the command line**, if you ever want it:
  ```sh
  virsh list --all
  ```
  ```sh
  virsh start <name>
  ```
  ```sh
  virsh shutdown <name>
  ```
- **Guests don't start by themselves** at boot (`onBoot = "ignore"`), unless
  you tick autostart on a machine. On host shutdown they are asked to shut
  down properly rather than being suspended to disk.

## Testing a flakeos change in a VM

A nice use of all this: try a risky change on a fake machine first.

- Install NixOS in a VM from the Minimal ISO, following
  [install.md](install.md). In a VM the virtual disk usually has no
  `/dev/disk/by-id/` name, so use `DISK=/dev/vda`.
- **Switch on 3D acceleration** in the VM's settings — niri needs it.
- You now have a throwaway flakeos you can break freely, with snapshots to
  jump back to.

## When something goes wrong

- ***"The display backend does not have OpenGL support enabled"*** — the
  **Video** device has *3D acceleration* ticked while the **Display Spice**
  device has no *OpenGL*. The two belong together. Either tick OpenGL on the
  Display page (it can only be ticked while *Listen type* is **None**), or
  untick 3D acceleration on the Video page — a Linux guest runs fine without
  it, the desktop is then drawn by the CPU.
- **The guest is stuck at a small resolution** — see
  [Your own resolution](#5-your-own-resolution).
- **Copy and paste does nothing** — see [The clipboard](#6-the-clipboard).
  After a rebuild, log out and in once so niri starts the new helpers.
- **The Windows installer shows no disk** — it has no VirtIO driver yet, see
  [inside the guest](#4-the-other-half-inside-the-guest).
- **No network in the guest** — that is libvirt's NAT switch. On *this*
  machine:
  ```sh
  systemctl status libvirt-default-network
  ```
  That service starts it at every boot (libvirt ships it switched off, which
  is the two `virsh` commands every other guide starts with).
- **virt-manager won't connect** — is the service running?
  ```sh
  systemctl status libvirtd
  ```
  And are you in the group? (You are, via `modules/users/slider.nix`, but a
  freshly added user needs a logout.)
  ```sh
  groups
  ```
- **A machine won't start, no useful error** — libvirt's own log:
  ```sh
  journalctl -u libvirtd -b -e
  ```
  ```sh
  sudo cat /var/log/libvirt/qemu/<machine-name>.log
  ```
- **The guest is slow** — check CPU Model is `host-passthrough` and the disk
  bus is `VirtIO`. Those two account for most of it.
