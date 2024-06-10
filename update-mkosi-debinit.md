% update-mkosi-debinit(1)
%
%

# NAME

update-mkosi-debinit - Simple debian package example

# SYNOPSIS

`update-mkosi-debinit OUTPUT [VERSION]`

# DESCRIPTION

This command builds initramfs file.

## Command Line Arguments

`OUTPUT`

: Represents path where the built artefact should be stored.
When the Linux kernel exists at `/boot/vmlinuz-6.7.12-amd64`,
usually initramfs file should be saved at `/boot/initrd.img-6.7.12-amd64`.

`VERSION`

: Sets the version of the current kernel.
Format should be similar to the output of `uname -r`.
Default value is `uname -r`.
