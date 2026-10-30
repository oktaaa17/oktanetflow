---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap installasi Ubuntu Server Cloud di Debian. Pelajari bagaimana menginstall Ubuntu Server di D ebian."
  - - meta
    - name: keywords
      content: "Ubuntu Server, Installasi Ubuntu Server, D ebian, Jaringan Komputer, Mikrotik Lab Indonesia, Oktanetflow"
  - - meta
    - name: author
      content: "Oktanetflow"
  # Open Graph (Facebook, LinkedIn, Discord)
  - - meta
    - property: "og:title"
      content: "Installasi Mikrotik RouterOS CHR di D  ebian - Oktanetflow"
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

# Setup idrac server with debian

# iDRAC + Debian Setup Guide

## 1. iDRAC Network Setup

1. Boot server → press **F2** during POST → enter System Setup
2. Navigate to **iDRAC Settings › Network › IPv4 Settings**
3. Assign static IP:
   ```
   IP Address  : 192.168.x.x
   Subnet Mask : 255.255.255.0
   Gateway     : 192.168.x.1
   ```
4. Apply → reboot → access web UI at `https://<idrac-ip>`

> Default credentials: `root / calvin` — change after first login.

---

## 2. Debian Install via iDRAC Virtual Media

1. Open **Virtual Console › Virtual Media › Connect Virtual Media**
2. Map D   ebian `.iso` via **Map CD/DVD**
3. Set **Next Boot › Virtual CD/DVD/ISO** (one-shot, not permanent)
4. Reboot → press **F11** → select **Virtual Optical Drive**
5. Follow installer → assign management IP, gateway, DNS → reboot

> Use one-shot boot to avoid looping on ISO after install.

## 3. Configuring Debian source list
```bash
echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list #v12

echo "deb http://deb.debian.org/debian trixie main" > /etc/apt/sources.list #v13

apt update
apt install openssh-server -y
```

> Use one-shot boot to avoid looping on ISO after install.

## 4. Verification

- [ ] iDRAC accessible at `https://<idrac-ip>`
- [ ] Debian web UI reachable at `https://<Debian-ip>:8006`
- [ ] VM starts without errors
- [ ] SSH into debian server works
