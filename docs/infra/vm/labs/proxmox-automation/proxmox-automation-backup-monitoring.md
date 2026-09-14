---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap monitoring backup Proxmox Automation. Pelajari bagaimana melakukan monitoring backup Proxmox Automation."
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

# Proxmox Automation Backup Monitoring

## 1. Prerequisites and Installation

### Step 1: Prerequisites

- Ensure you already have [Proxmox](https://www.proxmox.com/en/) installed and running on your server.
- Ensure you have virtual machine with backup content.

### Step 2: Configuration Roles, API-TOKEN, Permissions

- Open the Proxmox web interface.

#### Step 2.1: Datacenter > Permissions > Roles

```bash
Format: <role_name> [privilege1, privilege2, ...]
create role BackupAudit: datastore.allocate, datastore.audit, sys.audit, vms.audit, vm.backup
```

#### Step 2.2: Datacenter > Permissions > API-TOKEN

```bash
Format: <User> <Token-ID> <Privilege Separation>
Add Token: <root@pam> <BackupAudit> <True>
```

#### Step 2.3: Datacenter > Permissions

```bash
Format: <Path> <API-TOKEN> <Role> <Propagate>
Node:
Add API Token: </nodes/{node}>  <root@pam> <BackupAudit> <BackupAudit> <False>
Storage:
Add API Token: </storage/{storage}>  <root@pam> <BackupAudit> <BackupAudit> <True>
VM:
Add API Token: </vms>  <root@pam> <BackupAudit> <BackupAudit> <True>
```

::: info
Note: BackupAudit role will be created with the specified privileges. Be sure to assign privileges while creating the role.
:::

## 4. Verification

- **Check 1:** Are Backup Connections Established?
- **Check 2:** Are Role, API-TOKEN, and Permissions Configured Correctly?
- **Downloads:**

- <ButtonVue variant="secondary" as="a" class="no-underline!" href="./backup-list-cron-demo.sh" download>
  backup-list-cron-demo.sh(Fetch Backup List Critical Checkup)
  </ButtonVue>

- <ButtonVue variant="secondary" as="a" class="no-underline!" href="./backup-test-connection.sh" download>
  backup-test-connection.sh(Test Backup Connection)
  </ButtonVue>
