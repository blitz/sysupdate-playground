{ pkgs }:
let
  # A helper script to run the disk images above.
  qemu-efi = pkgs.writeShellApplication {
    name = "qemu-efi";

    runtimeInputs = [ pkgs.qemu ];

    text = ''
      if [ $# -lt 2 ]; then
        echo "Usage: qemu-efi ARCH disk-image [qemu-args...]" >&2
        exit 1
      fi

      ARCH="$1"
      DISK="$2"
      shift; shift


      case "$ARCH" in
           x86_64)
              qemu-system-x86_64 \
                -smp 2 -m 2048 -machine q35,accel=kvm \
                -bios "${pkgs.OVMF.fd}/FV/OVMF.fd" \
                -snapshot \
                -serial stdio -hda "$DISK" "$@"
              ;;
           aarch64)
              if [ ! -f .aarch-efi.img ]; then
                cat "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/FV/QEMU_EFI.fd" > .aarch-efi.img
                truncate -s 64m .aarch-efi.img
              fi

              if [ ! -f .aarch-var.img ]; then
                cat "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/FV/QEMU_VARS.fd" > .aarch-var.img
                truncate -s 64m .aarch-var.img
              fi

              # See  https://ubuntu.com/server/docs/boot-arm64-virtual-machines-on-qemu
              qemu-system-aarch64 -machine virt -smp 2 -m 2048 -cpu max \
                                  -serial stdio \
                                  -drive if=pflash,format=raw,file=.aarch-efi.img,readonly=on \
                                  -drive if=pflash,format=raw,file=.aarch-var.img \
                                  -drive if=none,file="$DISK",id=hd,snapshot=on \
                                  -device virtio-blk-device,drive=hd -device VGA \
                                  "$@"
              ;;
           riscv64)
              if [ ! -f .riscv-efi.img ]; then
                cat "${pkgs.pkgsCross.riscv64.OVMF.fd}/FV/RISCV_VIRT_CODE.fd" > .riscv-efi.img
                truncate -s 32m .riscv-efi.img
              fi

              if [ ! -f .riscv-var.img ]; then
                cat "${pkgs.pkgsCross.riscv64.OVMF.fd}/FV/RISCV_VIRT_VARS.fd" > .riscv-var.img
                truncate -s 32m .riscv-var.img
              fi

              # See https://github.com/tianocore/edk2/blob/master/OvmfPkg/RiscVVirt/README.md
              qemu-system-riscv64 \
                -M virt,pflash0=pflash0,pflash1=pflash1,acpi=off \
                -m 4096 -smp 2 \
                -serial stdio \
                -device virtio-gpu-pci \
                -device qemu-xhci \
                -device usb-kbd \
                -device virtio-rng-pci \
                -blockdev node-name=pflash0,driver=file,read-only=on,filename=.riscv-efi.img \
                -blockdev node-name=pflash1,driver=file,filename=.riscv-var.img \
                -netdev user,id=net0 \
                -device virtio-net-pci,netdev=net0 \
                -device virtio-blk-device,drive=hd0 \
                -drive if=none,file="$DISK",id=hd0,snapshot=on \
                "$@"
              ;;
           *)
              echo "Unknown architecture: $ARCH" >&2
              exit 1
              ;;
      esac
    '';
  };
in
{
  devShells.default = pkgs.mkShell {
    packages = [
      qemu-efi
    ];
  };

  packages = {
    inherit qemu-efi;
  };
}
