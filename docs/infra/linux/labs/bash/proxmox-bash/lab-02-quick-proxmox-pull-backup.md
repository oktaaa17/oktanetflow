---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap Automatisasi VM di Proxmox. Pelajari bagaimana membuat VM otomatisasi di Proxmox."
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

# Lab 01: Bash Scripting Automation

## 1. Bash Quick Proxmox Pull Backup

```bash
bash <(curl -fsSL https://oktanetflow.vercel.app/infra/linux/labs/bash/proxmox-bash/pve-pull-backup.sh)
```

::: info
Note: Run in a Proxmox Linux environment with Bash installed. This script will pull the latest backup from your Proxmox server. It helps in quickly retrieving the backup files for restoration or migration purposes.
:::
