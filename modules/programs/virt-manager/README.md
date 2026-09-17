# Virtual machines

A virtual machine is a whole second computer running in a window on this one.
You install an operating system into it, use it, break it, throw it away — the
machine you are sitting at is never touched. Good for trying another Linux,
keeping a Windows around, or testing a flakeos change before it goes on real
hardware.

**How it works.** Three pieces do the work:

| piece | what it does |
|---|---|
| KVM | the part in the kernel. It hands the guest *real* CPU cores instead of imitating them — that is why a machine can feel almost like a normal PC |
| QEMU | builds the rest of the PC around those cores: disk, network, screen, sound |
| libvirt | remembers the machines and starts them |

The window you click in is **Virtual Machine Manager**, in the launcher.
Everything the usual guides make you do by hand — install the packages, switch
the service on, put your user in the `libvirtd` group, start the `default`
network — is already done by `grouped/vm.nix`.

The machines and their disks live in `/var/lib/libvirt/images`, not in this
repo. They survive rebuilds. Deleting a machine in the manager deletes them.

The repo files behind all this: `system/libvirt.nix` (the machinery),
`programs/virt-manager/virt-manager.nix` (the window and what a new machine
starts with) and `programs/niri/niri.nix` (the clipboard bridge, see below).

## Contents

- [What you need](#what-you-need)
1. [Create the machine](#1-create-the-machine)
2. [The settings that matter](#2-the-settings-that-matter)
3. [Living in the window](#3-living-in-the-window)
4. [The other half: inside the guest](#4-the-other-half-inside-the-guest)
5. [Your own resolution](#5-your-own-resolution)
6. [The clipboard](#6-the-clipboard)
- [Handy extras](#handy-extras)
- [When something goes wrong](#when-something-goes-wrong)

## What you need

- **The `vm` bundle in your machine.** zeus has it. If a host does not, add
  `vm` to the list in `modules/hosts/<host>/<host>.nix` and rebuild.
- **An ISO** of the system you want to install. Download it first; the wizard
  asks for the file.
- **Space**: 30–60 GB for a desktop guest. The disk file only grows to what is
  really used.

## 1. Create the machine

**File → New Virtual Machine → Local install media**, pick the ISO, give the
machine memory and CPUs, and on the last page tick **Customize configuration
before install**.

That last tick is the important one: it opens the machine's settings *before*
it boots for the first time, and a few of them cannot be changed sensibly
afterwards.

## 2. The settings that matter

| page | set | why |
|---|---|---|
| Memory | about a quarter of this machine's RAM (`16384` MiB on a 64 GB machine) | enough for a full desktop guest, with plenty left for the host |
| CPUs → vCPU allocation | about half the threads (`16` of 32) | the guest gets real cores, the host keeps enough to stay responsive |
| CPUs → Topology | 1 socket, half the vCPUs as cores, 2 threads (16 vCPUs → 1 × 8 × 2) | the guest sees one normal CPU with hyperthreading instead of a pile of single-core sockets — Windows and most schedulers handle that much better |
| CPUs → Model | `host-passthrough` | already set: the guest sees this machine's real CPU with all its instructions. The biggest single speed setting |
| Overview → Firmware | `UEFI` | already set: guests boot like a modern PC. Windows 11 needs it |
| Overview → Chipset | `Q35` | the modern virtual mainboard (PCIe, UEFI). The wizard picks it for anything recent |
| Disk 1 → Disk bus | `VirtIO` | the guest talks to the disk directly instead of through an emulated SATA controller — the biggest difference in disk speed |
| Disk 1 → Advanced → Discard mode | `unmap` | deleting files in the guest gives the space back on the host |
| NIC → Device model | `virtio` | the same idea for the network card |
| Display Spice | keep Spice; *Listen type* **None** and tick **OpenGL**, render node = the GPU your monitors are on | clipboard, automatic resolution, USB devices. OpenGL belongs to the 3D below; the dropdown names every GPU, pick the one drawing your desktop, not the CPU's built-in one |
| Video | `Virtio`, and tick **3D acceleration** for a Linux guest | lets the guest use the real GPU for its desktop. Linux only: Windows has no driver for it, leave both off there |
| TPM (Add Hardware → TPM) | emulated TPM 2.0, only for Windows 11 | Windows 11 refuses to install without one |

Then **Begin Installation**, and install the system in the window like on a
real PC. Memory, CPUs and disk size can be changed later in the machine's
settings, while it is shut down.

## 3. Living in the window

- The pointer is released from the machine's window with **Ctrl + Alt**.
- **View → Fullscreen** shows the guest 1:1. The toolbar slides back in when
  you push the mouse to the top edge.
- **View → Scale display → Only when fullscreen** is the sane setting: in a
  window the picture is scaled to fit, in fullscreen it is exact.
- The machine keeps running when you close its window. The manager window
  lists it; double-click to look again.

## 4. The other half: inside the guest

The last bit of "feels like hardware" happens *inside* the machine.

- **Linux guest:** install its `spice-vdagent` and `qemu-guest-agent`
  packages. On a NixOS guest, two lines do it:

  ```nix
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  ```

  `qemu-guest-agent` is what lets the host ask the guest things (its IP, its
  screen size) and shut it down properly. `spice-vdagent` is the clipboard —
  on a niri guest it needs two more lines, see [The clipboard](#6-the-clipboard).

- **Windows guest:** Windows has no VirtIO drivers, so its installer shows no
  disk at all. Get the driver ISO:

  ```
  nix build --no-link --print-out-paths nixpkgs#virtio-win.src
  ```

  Attach the path it prints as a second CD-ROM (Add Hardware → Storage →
  Device type CDROM), and during the Windows setup click *Load driver* → the
  `viostor` folder. After the install, run `virtio-win-guest-tools.exe` from
  the same ISO for the rest (network, display, clipboard).

## 5. Your own resolution

A virtual graphics card has no monitor to ask, so QEMU invents one: a fixed
list of classic sizes, none of them yours. The guest picks the best it is
offered — often 1280x800 — and a guest agent can only resize it on X11 or
GNOME, not on niri. So tell the card its size:

1. Shut the machine down (the setting is read at boot).
2. Its window → the **i** button (virtual hardware details) → **Video
   Virtio** → the **XML** tab.
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
machines the clipboard has to pass through XWayland. A GNOME or KDE guest hides
that — they start the agent themselves and their compositors carry the X
clipboard across. With niri on both sides, three pieces are missing:

| where | what is missing | fixed by |
|---|---|---|
| guest | nothing starts the agent's client | `spawn-at-startup "spice-vdagent"` |
| both | XWayland's clipboard and niri's are separate: xwayland-satellite does not carry anything between them | `niri-clipboard-bridge` in `programs/niri/niri.nix`, spawned at startup |
| host | as a Wayland client virt-manager never notices that something else here copied, so the clipboard stops travelling the moment the guest copies | virt-manager runs on XWayland, `programs/virt-manager/virt-manager.nix` |

Both host halves are already done by this repo. A NixOS guest needs the agent,
the same bridge (copy the `niri-clipboard-bridge` package out of
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

`spice-vdagent` has to come from niri's `spawn-at-startup`, not from a systemd
user service: `spice-vdagentd` only accepts a client that belongs to the active
login session and drops every other one. Text only, no images.

## Handy extras

- **A shared folder:** Add Hardware → Filesystem, source `/mnt/data`, target
  tag `data`. In a Linux guest: `mount -t virtiofs data /mnt/data`.
- **A USB stick or controller in the guest:** Virtual Machine → Redirect USB
  device, while the machine runs.
- **Snapshots:** the camera icon in the machine's window. Takes a picture of
  the whole machine you can jump back to (qcow2 disks can do this).
- **Every knob libvirt has:** the XML tab in the machine's details.

## When something goes wrong

- *"The display backend does not have OpenGL support enabled"* — the **Video**
  device has *3D acceleration* ticked while the **Display Spice** device has no
  *OpenGL*. The two belong together. Either tick OpenGL on the Display page (it
  can only be ticked while *Listen type* is **None**), or untick 3D
  acceleration on the Video page — a Linux guest runs fine without it, the
  desktop is then drawn by the CPU.
- *The guest is stuck at a small resolution* — see
  [Your own resolution](#5-your-own-resolution).
- *Copy and paste does nothing* — see [The clipboard](#6-the-clipboard). After
  a rebuild, log out and in once so niri starts the new helpers.
- *The Windows installer shows no disk* — it has no VirtIO driver yet, see
  [inside the guest](#4-the-other-half-inside-the-guest).
- *No network in the guest* — `systemctl status libvirt-default-network` on
  this machine; that service starts libvirt's NAT switch at every boot.
