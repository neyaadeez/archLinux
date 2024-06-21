#!/bin/bash

# Set the console keyboard layout to US
loadkeys us

# Verify if the system is booted in UEFI mode
if [ -d /sys/firmware/efi/efivars ]; then
  echo "System is in UEFI mode"
else
  echo "System is not in UEFI mode. Please boot in UEFI mode."
  exit 1
fi

# Set the system clock
timedatectl set-ntp true

# Partition the disk
parted /dev/sda --script mklabel gpt \
  mkpart primary fat32 1MiB 1GiB \
  set 1 esp on \
  mkpart primary ext4 1GiB 100%

# Format the partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount the file systems
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Select the mirrors
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Install essential packages
pacstrap /mnt base linux linux-firmware

# Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt <<EOF

# Set the time zone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Set the hostname
echo "neyaadeez" > /etc/hostname

# Install and enable NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Set the root password
echo "root:1234" | chpasswd

# Install and configure GRUB
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Unmount all partitions and reboot
umount -R /mnt
reboot
