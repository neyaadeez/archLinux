#!/bin/bash

hostname=$(cat /hostname.txt)

create_new_user() {
    read -p "Enter the username for the new user: " username
    read -s -p "Enter the password for the new user: " user_password
    echo
    read -s -p "Confirm the password for the new user: " user_password_confirm

    if [ "$user_password" != "$user_password_confirm" ]; then
        echo "Passwords do not match. Please run the script again."
        exit 1
    fi

    # Check for the next available UID starting from 1000
    for uid in {1000..2000}; do
        if ! id -u "$uid" &>/dev/null; then
            new_uid="$uid"
            break
        fi
    done

    if [ -z "$new_uid" ]; then
        echo "Error: No available UID found in the range 1000-2000."
        exit 1
    fi

    # Create the new user with the determined UID
    useradd -u "$new_uid" -m -G wheel -s /bin/bash "$username"
    echo "$username:$user_password" | chpasswd

    # Uncomment the wheel group sudo access in sudoers file
    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

    echo "User '$username' created successfully with UID $new_uid."
}

create_new_user

ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

timedatectl set-ntp true

pacman -Syu --noconfirm base-devel linux-headers

read -p "Do you want to install a GUI? (yes/no): " install_gui

if [ "$install_gui" == "yes" ]; then
  echo "Select a GUI environment to install:"
  echo "1. GNOME"
  echo "2. KDE Plasma"
  echo "3. XFCE"
  echo "4. Cinnamon"
  echo "5. MATE"
  echo "6. LXQt"

  echo "Approximate memory required for installation:"
  echo "1. GNOME: 2.5 GB - 3 GB"
  echo "2. KDE Plasma: 2 GB - 2.5 GB"
  echo "3. XFCE: 800 MB - 1.2 GB"
  echo "4. Cinnamon: 1.2 GB - 1.5 GB"
  echo "5. MATE: 1 GB - 1.5 GB"
  echo "6. LXQt: 400 MB - 600 MB"
  echo

  read -p "Enter your choice (1-6): " gui_choice

  case $gui_choice in
    1)
      pacman -S --noconfirm xorg gnome gnome-extra gdm
      systemctl enable gdm
      ;;
    2)
      pacman -S --noconfirm xorg plasma-desktop
      systemctl enable sddm
      ;;
    3)
      pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm
      systemctl enable lightdm
      ;;
    4)
      pacman -S --noconfirm xorg cinnamon
      systemctl enable lightdm
      ;;
    5)
      pacman -S --noconfirm xorg mate mate-extra lightdm
      systemctl enable lightdm
      ;;
    6)
      pacman -S --noconfirm xorg lxqt sddm
      systemctl enable sddm
      ;;
    *)
      echo "Invalid choice. Skipping GUI installation."
      ;;
  esac
else
  echo "Skipping GUI installation."
fi

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$hostname" > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $hostname.localdomain $hostname" >> /etc/hosts

pacman -S --noconfirm sudo vim git

pacman -S --noconfirm ufw
ufw enable

pacman -Syu --noconfirm

rm /hostname.txt

echo "Setup complete. The system will now reboot."
reboot
