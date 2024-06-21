### Arch Linux Installation Script for Virtual Machines

This repository provides scripts to automate the installation and post-installation setup of Arch Linux on virtual machines. These scripts are intended to be used with an Arch Linux ISO and an internet-connected virtual machine.

#### Steps to Use the Scripts

1. **Download Arch Linux ISO:**
   - Obtain the Arch Linux ISO from [https://archlinux.org/download/](https://archlinux.org/download/).

2. **Configure Virtual Machine:**
   - Ensure EFI is enabled in the virtual machine settings if you want to install in UEFI mode.

3. **Run Installation Script:**
   - Open a terminal in the Arch Linux virtual machine and execute the following commands:
     ```bash
     curl -O https://neyaadeez.com/archLinuxInstall.sh
     chmod +x archLinuxInstall.sh
     ./archLinuxInstall.sh
     ```
   - Follow the prompts to enter the required information:
     - **Hostname:** Name for the system.
     - **Root Password:** Password for the root user.
     - **Root Partition Size:** Size of the root partition (`/`). The script reserves space for the boot partition (1 GiB for UEFI or none for BIOS).
     - **Swap Partition:** Option to create a swap partition and its size.
   
   - **Details:**
     - The script detects whether the system is running in UEFI or BIOS mode.
     - Sets the system clock and partitions the disk accordingly:
       - Creates a primary partition for the root filesystem (`/`), with the size specified by the user. After calculating space for the optional swap partition, all remaining available space on the disk is allocated to the root partition for optimal system performance and management.
       - Optionally creates a swap partition, if selected by the user.
     - Installs essential packages, configures the system, installs GRUB bootloader, and sets up the system for reboot.

4. **Post-Installation Setup:**
   - After rebooting the system following the installation script, download and execute the post-installation script:
     ```bash
     curl -O https://neyaadeez.com/archLinuxPostInstall.sh
     chmod +x archLinuxPostInstall.sh
     ./archLinuxPostInstall.sh
     ```
   - The post-installation script completes the setup:
     - Sets timezone and hardware clock.
     - Installs base development tools, Linux headers, and optionally installs a GUI environment (GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt) based on user choice.
     - Configures locale settings, hostname, hosts file, sudoers file, firewall (ufw), and installs essential utilities.
     - Cleans up temporary files and reboots the system for changes to take effect.

#### Notes
- **Internet Connection:** Ensure the virtual machine has a working internet connection throughout the installation and setup process.
- **Partitioning:** The root partition (`/`) is configured as primary. After calculating space for the optional swap partition, all remaining available space on the disk is allocated to the root partition for optimal system performance and management.

These scripts automate the installation and configuration of Arch Linux in a virtual machine, making the setup process straightforward and efficient. For more details or updates, refer to the script files (`archLinuxInstall.sh` and `archLinuxPostInstall.sh`) provided in this repository.
