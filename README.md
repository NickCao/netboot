# netboot
boot NixOS from iPXE on machines with only 700M of memory

## usage
```ipxe
#!ipxe
set cmdline sshkey="ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
chain https://github.com/NickCao/netboot/releases/download/latest/ipxe
```
