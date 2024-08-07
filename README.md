
```console
$ nix build .#appliance_17_image 
  
$ qemu-system-x86_64 -smp 8 -m 4096 -cpu host -machine q35,accel=kvm -bios OVMF.fd -snapshot -hda result/disk.qcow2 -serial stdio
```

For the OVMF.fd:

```console
$ nix build nixpkgs#OVMF.fd                                                                                                      
$ ls result-fd/FV/OVMF.fd 
```
