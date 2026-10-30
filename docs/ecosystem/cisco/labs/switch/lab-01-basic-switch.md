---
outline: deep
head:
  - - meta
    - name: description
      content: "Belajar dasar switching Cisco Packet Tracer: Cara konfigurasi IP PC, memahami MAC Address Table, dan verifikasi konektivitas antar perangkat."
  - - meta
    - name: keywords
      content: "Cisco Packet Tracer, Tutorial Switch, Networking Lab, MAC Address Table, Dasar Jaringan, Oktanetflow, Belajar Jaringan"
---

# Lab 01: Dasar Switch

## 1. Concept High-Level

> **TL;DR:** A Switch connects multiple devices (PCs, Servers, Printers) within a Local Area Network (LAN) and intelligently directs data only to the specific destination device using MAC addresses.

- **Role:** Layer 2 Data Forwarding
- **Standard:** Cisco IOS (Internetwork Operating System)
- **Why use it?** Efficient, Fast, Scalable and solved the problem of Hubs(Collision Domain)

## 2. Lab Topology

| Device  | Interface    | IP Address  | Role        |
| :------ | :----------- | :---------- | :---------- |
| Switch0 | fa0/1, fa1/1 | -           | Core Switch |
| PC-1    | fa0/1-fa0    | 192.168.1.1 | Access      |
| PC-2    | fa1/1-fa0    | 192.168.1.2 | Access      |

## 3. Configuration Guide

### Step 1: Base Config

Open a command prompt and type the following command:

```bash
PC-1>
C:\>ipconfig 192.168.1.1 255.255.255.252 192.168.1.1
PC-2>
C:\>ipconfig 192.168.1.2 255.255.255.252 192.168.1.1
```

::: details
`ipconfig`: Set the IP address, subnet mask, and default gateway for a network interface.
:::

## 4. Verification & Troubleshooting

**Key Command:**

- **Network Test:** `PC-1: ping 192.168.1.2`, `PC-2: ping 192.168.1.1`
- **Mac Address Check:**

```bash
Switch>en
Switch#sh mac-addr
          Mac Address Table
-------------------------------------------

Vlan    Mac Address       Type        Ports
----    -----------       --------    -----

   1    0007.ecc7.96d9    DYNAMIC     Fa0/1
   1    00e0.f9d6.d01e    DYNAMIC     Fa1/1
```

- **Check 1:** Are neighbors established?
- **Check 2:** Are MAC addresses showing?

## 5. My Personal Notes (The Oktanetflow Touch)

- **Difficulty:** Easy
- **Mistakes I Made:** Mac Address Learning, make sure to check neighbors first by ping command before show mac address.
- **Related Resources:**
  - [Switch Concepts](/guide/layer-2/switch-concept)
- **Downloads:**
<ButtonVue variant="secondary" as="a" class="no-underline!" href="./lab-switch-dasar.pkt" download>
  lab-switch-dasar.pkt(Full Config)
</ButtonVue>