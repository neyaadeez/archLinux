#!/bin/bash

loadkeys us

if [ -d /sys/firmware/efi/efivars ]; then
  uefi_available=true
else
  uefi_available=false
fi

if [ -e /sys/firmware/bios ]; then
  bios_available=true
else
  bios_available=false
fi

if [ "$uefi_available" == true ] && [ "$bios_available" == true ]; then
  read -p "Both UEFI and BIOS are available. Which mode do you want to use? (uefi/bios): " boot_mode
  while [[ "$boot_mode" != "uefi" && "$boot_mode" != "bios" ]]; do
    echo "Invalid choice. Please enter 'uefi' or 'bios'."
    read -p "Which mode do you want to use? (uefi/bios): " boot_mode
  done
elif [ "$uefi_available" == true ]; then
  boot_mode="uefi"
  echo "Only UEFI is available. Proceeding with UEFI installation."
elif [ "$bios_available" == true ]; then
  boot_mode="bios"
  echo "Only BIOS is available. Proceeding with BIOS installation."
else
  echo "Neither UEFI nor BIOS is available on this system. Exiting."
  exit 1
fi

timedatectl set-ntp true

total_space=$(lsblk -dn -o SIZE -b /dev/sda | awk '{ print int($1/1024/1024/1024) }')
echo "Total disk space available: $total_space GiB"

# Reserved space for boot partition
if [ "$boot_mode" == "uefi" ]; then
  reserved_space=1  # GiB
else
  reserved_space=0  # BIOS doesn't require a separate boot partition
fi

echo "Note: $reserved_space GiB will be reserved for the $boot_mode boot partition."

read -p "Enter hostname: " hostname
read -s -p "Enter root password: " root_password
echo
read -p "Enter space for root partition (in GiB, excluding $reserved_space GiB for $boot_mode boot partition): " root_space

while [[ $root_space -le $reserved_space || $root_space -gt $total_space ]]; do
  echo "Invalid root partition size. Please enter a value between $((reserved_space + 1)) and $total_space GiB."
  read -p "Enter space for root partition (in GiB, excluding $reserved_space GiB for $boot_mode boot partition): " root_space
done

read -p "Do you want a swap partition? (yes/no): " create_swap

if [ "$create_swap" == "yes" ]; then
  read -p "Enter swap space (in GiB): " swap_space

  while [[ $swap_space -le 0 || $((root_space + swap_space)) -gt $total_space ]]; do
    echo "Invalid swap partition size. Please enter a value between 1 and $((total_space - root_space)) GiB."
    read -p "Enter swap space (in GiB): " swap_space
  done

  swap_end=$((root_space + swap_space))
else
  swap_end=$root_space
fi

if [ "$boot_mode" == "uefi" ]; then
  parted /dev/sda --script mklabel gpt \
    mkpart primary fat32 1MiB 1GiB \
    set 1 esp on \
    mkpart primary ext4 1GiB "${root_space}GiB"

  echo "UEFI boot partition is taking 1 GiB space."

  if [ "$create_swap" == "yes" ]; then
    parted /dev/sda --script mkpart primary linux-swap "${root_space}GiB" "${swap_end}GiB"
  fi

  mkfs.fat -F32 /dev/sda1
  mkfs.ext4 /dev/sda2

  if [ "$create_swap" == "yes" ]; then
    mkswap /dev/sda3
    swapon /dev/sda3
  fi

  mount /dev/sda2 /mnt
  mkdir /mnt/boot
  mount /dev/sda1 /mnt/boot
else
  parted /dev/sda --script mklabel msdos \
    mkpart primary ext4 1MiB "${root_space}GiB"

  echo "BIOS boot partition is taking $reserved_space GiB space."

  if [ "$create_swap" == "yes" ]; then
    parted /dev/sda --script mkpart primary linux-swap "${root_space}GiB" "${swap_end}GiB"
  fi

  mkfs.ext4 /dev/sda1

  if [ "$create_swap" == "yes" ]; then
    mkswap /dev/sda2
    swapon /dev/sda2
  fi

  mount /dev/sda1 /mnt
fi

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt <<EOF

ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

echo "$hostname" > /etc/hostname

pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

echo "root:$root_password" | chpasswd

if [ "$boot_mode" == "uefi" ]; then
  pacman -S --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  pacman -S --noconfirm grub
  grub-install --target=i386-pc /dev/sda
fi

grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "$hostname" > /mnt/hostname.txt

umount -R /mnt
reboot
