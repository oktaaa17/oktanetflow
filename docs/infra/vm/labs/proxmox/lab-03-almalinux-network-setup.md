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

# Setup AlmaLinux Network

## 1. AlmaLinux Network Setup

1. Terminal → `nmtui`
2. Navigate to **Edit Connections › Interface › <Edit..>**
3. Assign static IP:
   ```
   IP Address  : 192.168.x.x
   Subnet Mask : 255.255.255.0
   Gateway     : 192.168.x.1
   DNS         : 8.8.8.8
   ```
4. Apply:

- [x] Automatically connect
- [x] Available to all users

5. Ok → `Back` → `Exit`

## 2. Verification

```bash
nmcli connection reload
nmcli connection up
```
