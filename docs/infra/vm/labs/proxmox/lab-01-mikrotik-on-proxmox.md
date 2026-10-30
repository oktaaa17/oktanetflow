---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap installasi Mikrotik RouterOS CHR di Proxmox.Pelajari bagaimana menginstall Mikrotik RouterOS di Proxmox."
  - - meta
    - name: keywords
      content: "Mikrotik RouterOS, Installasi Mikrotik RouterOS, Proxmox, Jaringan Komputer, Mikrotik Lab Indonesia, Oktanetflow"
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

# Installation Mikrotik RouterOS CHR on Proxmox

## 1. Prerequisites and Installation

### Step 1: Prerequisites

- Ensure you already have [Proxmox](https://www.proxmox.com/en/) installed and running on your server..

### Step 2: Installation

- Copy Link CHR Raw disk image [CHR RouterOS](https://mikrotik.com/download/chr)

#### Step 2.1: Installation on Proxmox

```bash
root@pve01:~# cd /dev/pve
root@pve01:/dev/pve# wget https://download.mikrotik.com/routeros/7.22.1/chr-7.22.1.img.zip
root@pve01:/dev/pve# gunzip -c chr-7.22.1.img.zip > chr-7.22.1.img
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

## 4. Verification 

- **Check 1:** Are VMs can start?
- **Check 2:** Are Mikrotik RouterOS able to connect via winbox?