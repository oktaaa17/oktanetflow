---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap installasi Ubuntu Server Cloud di Proxmox. Pelajari bagaimana menginstall Ubuntu Server di Proxmox."
  - - meta
    - name: keywords
      content: "Ubuntu Server, Installasi Ubuntu Server, Proxmox, Jaringan Komputer, Mikrotik Lab Indonesia, Oktanetflow"
  - - meta
    - name: author
      content: "Oktanetflow"
  # Open Graph (Facebook, LinkedIn, Discord)
  - - meta
    - property: "og:title"
      content: "Installasi Mikrotik RouterOS CHR di Proxmox - Oktanetflow"
  - - meta
    - property: "og:description"
      content: "Bagaimana membuat bootable USB OS installer menggunakan rufus."
  - - meta
    - property: "og:type"
      content: "article"
  - - meta
    - property: "og:image"
      content: "https://oktanetflow.vercel.app/ecosystem/mikrotik/labs/capstone/MIKROTIK_DASAR_TOPOLOGY.png" # Ganti dengan URL absolut gambar topologi
  # Twitter Card
  - - meta
    - name: "twitter:card"
      content: "summary_large_image"
  - - meta
    - name: "twitter:title"
      content: "Lab 01: Mikrotik Dasar Capstone - Oktanetflow"
  - - link
    - rel: canonical
      href: "https://oktanetflow.vercel.app/tools/bootable-usb-os-installer"
---

# Installation Ubuntu Server Cloud on Proxmox

## 1. Prerequisites and Installation

### Step 1: Prerequisites

- Ensure you already have [Proxmox](https://www.proxmox.com/en/) installed and running on your server..

### Step 2: Installation

- Copy Link Qcow2 disk image [Ubuntu Server](https://cloud-images.ubuntu.com/noble/current/)

#### Step 2.1: Installation on Proxmox

```bash
root@pve01:~# cd /dev/pve
root@pve01:/dev/pve# wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
root@pve01:/dev/pve# qm importdisk <vmid> <image name> <storage>
```

::: info
Note: In proxmox, create the VM without disc image.
:::

## 3. Configuration VM on Proxmox

### Step 3.1: Disc image Asignment
```bash
VM>Hardware>Disks>Unused Disk>Assig to VM(local-vmid-disk-id)
```

### Step 3.2 Boot Order
```bash
VM>Options>Boot-order>Order>1>local-vmid-disk-id
```

::: tip
Note: Make sure the order is the same as the order in step 3.2, and uncheck the bootable checkbox except the first boot order.
:::

### Step 3.3 Hardware Configuration
```bash
VM>Hardware>Processors>x86-64-v2
VM>Hardware>Add>Serial Port
VM>Hardware>Add>Cloud Init
```

### Step 3.4 Cloud Init Configuration
```bash
VM>Cloud Init>Add>password
VM>Cloud Init>IP-config>assign static ip address
VM>Cloud Init>Regenerate Image
```

::: info
Note: Just ping random ip address range base on your network to know your ip address is available for ubuntu server.
:::

### Step 3.4 Disc Reconfiguration
```bash
root@ubuntu-server24:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda       8:0    0  3.5G  0 disk
├─sda1    8:1    0  2.5G  0 part /
├─sda14   8:14   0    4M  0 part
├─sda15   8:15   0  106M  0 part /boot/efi
└─sda16 259:0    0  913M  0 part /boot
sr0      11:0    1    4M  0 rom
sr1      11:1    1 1024M  0 rom

root@ubuntu-server24:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.1M  196M   1% /run
/dev/sda1       2.4G  2.3G  115M  96% /
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M  117M  703M  15% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           197M   12K  197M   1% /run/user/0
root@ubuntu-server24:~# growpart /dev/sda 1
CHANGED: partition=1 start=2099200 old: size=5240799 end=7339998 new: size=9435103 end=11534302

root@ubuntu-server24:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.1M  196M   1% /run
/dev/sda1       2.4G  2.3G  115M  96% /
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M  117M  703M  15% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           197M   12K  197M   1% /run/user/0

root@ubuntu-server24:~# resize2fs /dev/sda1
resize2fs 1.47.0 (5-Feb-2023)
Filesystem at /dev/sda1 is mounted on /; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/sda1 is now 1179387 (4k) blocks long.

root@ubuntu-server24:~# df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           197M  1.1M  196M   1% /run
/dev/sda1       4.3G  2.3G  2.1G  53% /
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M  117M  703M  15% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
tmpfs           197M   12K  197M   1% /run/user/0

```

::: info
Note: VM>Hardware>Harddisk>Action>Resize
Snapshots first before performing change 
:::

## 4. Verification 

- **Check 1:** Are VMs can start?
- **Check 2:** Are Ubuntu Server able to connect via SSH?