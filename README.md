# systemd-repart / systemd-sysupdate Example

This repository contains an example of how to use
[systemd-repart](https://www.freedesktop.org/software/systemd/man/latest/systemd-repart.html#)
and
[systemd-sysupdate](https://www.freedesktop.org/software/systemd/man/latest/systemd-sysupdate.html)
to build immutable system images that can be updated over the
Internet.

See [x86.lol](https://x86.lol/) for blog posts about this setup:

1. [Immutable Systems: NixOS + systemd-repart + systemd-sysupdate](https://x86.lol/generic/2024/08/28/systemd-sysupdate.html)
1. Immutable Systems: Cross-Compiling for RISC-V using Flakes (to be published)

## How to Build the System Image

You need [Nix](https://nixos.org/) with enabled
[Flakes](https://wiki.nixos.org/wiki/Flakes). After that, you can
build the disk image:

```console
$ nix build .
```

After the build process, there will be a QEMU disk image `disk.qcow2`
in `result/`.

## Running the Demo

You can boot `result/disk.qcow2` produced in the previous step in any
virtualization solution that supports UEFI. For simplicity, you can
enter a development shell and boot it with the convenience script
`qemu-efi`:

```console
# This will take some time, because it compiles quite a bunch of stuff for
# RISC-V and ARM AArch64.
$ nix develop

$ qemu-efi x86_64 result/disk.qcow2
```

## Experimenting with the Demo

Once you have the demo running, you can see systemd-sysupdate and sysupdate-repart in action:

(I have removed parts of the console output for readability.)

```console
# List the update files.
% ls -lh /var/updates/
total 324M
-r--r--r-- 1 root root  43M Aug 11 15:47 appliance_18.efi.xz
-r--r--r-- 1 root root 282M Aug 11 15:47 store_18.img.xz

# See that systemd-sysupdate has found an update.
% systemd-sysupdate
  VERSION INSTALLED AVAILABLE ASSESSMENT
↻ 18                    ✓     candidate
● 17          ✓               current

# Apply the update.
% systemd-sysupdate update
Selected update '18' for install.
Making room for 1 updates…
Removed no instances.
⤵️ Acquiring /var/updates/appliance_18.efi.xz → /boot/EFI/Linux/appliance_18.efi...
Importing '/var/updates/appliance_18.efi.xz', saving as '/boot/EFI/Linux/.#sysupdateappliance_18.efifce0abb2fdba79a5'.
[...]
Successfully acquired '/var/updates/appliance_18.efi.xz'.
⤵️ Acquiring /var/updates/store_18.img.xz → /proc/self/fd/3p2...
Importing '/var/updates/store_18.img.xz', saving at offset 269484032 in '/dev/sda'.
[...]
Successfully acquired '/var/updates/store_18.img.xz'.
Successfully installed '/var/updates/appliance_18.efi.xz' (regular-file) as '/boot/EFI/Linux/appliance_18.efi' (regular-file).
Successfully installed '/var/updates/store_18.img.xz' (regular-file) as '/proc/self/fd/3p2' (partition).
✨ Successfully installed update '18'.

# Reboot into the new version.
% reboot
```

Once the system is back up, you can remove the last version. This would also happen automatically when the next version is installed.

```console
% systemd-sysupdate vacuum -m 1
```

Looking at the partition layout using `parted` before and after the update is also interesting!
