---
outline: deep
head:
  - - meta
    - name: description
      content: "Belajar dasar dynamic routing Cisco: Cara konfigurasi EIGRP  dan verifikasi konektivitas antar router."
  - - meta
    - name: keywords
      content: "Cisco Packet Tracer, Dynamic Routing, EIGRP, Networking Lab, Oktanetflow, Belajar Jaringan"
---

# Lab 03: Dasar Dynamic Routing <Badge type="warning" text=""/>

## 1. Concept High-Level

> **TL;DR:** Dynamic routing enables routers to automatically learn, evaluate, and adapt network paths across interconnected networks using protocols like OSPF or BGP, ensuring efficient packet forwarding without manual static route management.

- **Role:** Layer 3 (Network Layer) Packet Routing & Path Determination
- **Standard:** Cisco IOS / RFC Standards (OSPF: RFC 2328, BGP: RFC 4271)
- **Why use it?**
  - Automatically calculates optimal network paths and adapts to topology changes (failover).
  - Eliminates manual static route management on complex and growing networks.
  - Unlike Layer 2 switches (which forward frames within a LAN using MAC addresses), routers forward IP packets across different networks using routing tables.

## 2. Lab Topology

![Lab Topology](https://github.com/testing-abc17777/CISCO_UPT_BLK/blob/master/pertemuan-ke-22-senin-17-november-2025/src/assets/Screenshot%202025-12-17%20142839.png?raw=true)

##### AREA-1:

| Device | Interface    | IP Address                   | Role         |
| :----- | :----------- | :--------------------------- | :----------- |
| R-O    | se2/0, fa4/0 | 10.0.0.9/30, 10.0.0.1/30     | Core Switch  |
| R-3    | SE2/0, FA0/0 | 10.0.0.10/30, 192.168.1.0/24 | Child Router |
| PC-1   | fa0/0        | 192.168.1.2                  | Client       |

##### AREA-2:

| Device | Interface           | IP Address                             | Role         |
| :----- | :------------------ | :------------------------------------- | :----------- |
| R-1    | se2/0, fa4/0, fa5/0 | 10.0.0.13/30, 10.0.0.2/30, 10.0.0.5/30 | Core Switch  |
| R-4    | SE2/0, FA0/0        | 10.0.0.14/30, 192.168.2.0/24           | Child Router |
| PC-2   | fa0/0               | 192.168.2.2                            | Client       |

##### AREA-3:

| Device | Interface    | IP Address                   | Role         |
| :----- | :----------- | :--------------------------- | :----------- |
| R-2    | se2/0, fa4/0 | 10.0.0.6/30, 10.0.0.17/30    | Core Switch  |
| R-5    | SE2/0, FA0/0 | 10.0.0.18/30, 192.168.3.0/24 | Child Router |
| PC-3   | fa0/0        | 192.168.3.2                  | Client       |

## 3. Configuration Guide

### Step 1: Base Config

Open a command prompt and type the following command:

```bash
PC-1>
C:\>ipconfig 192.168.1.1 255.255.255.0 192.168.1.1
PC-2>
C:\>ipconfig 192.168.2.1 255.255.255.0 192.168.2.1
etc... (Follow the same pattern with previous table topology)
```

::: details
`ipconfig`: Set the IP address, subnet mask, and default gateway for a network interface.
:::

### Step 2: Protocol Specifics

#### Step 2.1: Router Port Configuration

- ##### AREA-1

```bash
R-3>
R-3>en
R-3#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
R-3(config)#interface Serial2/0
R-3(config-if)#ip address 10.0.0.1 255.255.255.252
R-3(config-if)exit
R-3(config)#interface Fa0/0
R-3(config-if)#ip address 192.168.1.1 255.255.255.0
etc... (Follow the same pattern with previous table topology)
```

- ##### AREA-2

```bash
R-4>
R-4>en
R-4#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
R-4(config)#interface Serial2/0
R-4(config-if)#ip address 10.0.0.14 255.255.255.252
R-4(config-if)exit
R-4(config)#interface Fa0/0
R-4(config-if)#ip address 192.168.2.1 255.255.255.0
etc... (Follow the same pattern with previous table topology)
```

- ##### AREA-3

```bash
R-5>
R-5>en
R-5#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
R-5(config)#interface Serial2/0
R-5(config-if)#ip address 10.0.0.18 255.255.255.252
R-5(config-if)exit
R-5(config)#interface Fa0/0
R-5(config-if)#ip address 192.168.3.1 255.255.255.0
etc... (Follow the same pattern with previous table topology)
```

::: tip
Configure for each ports.

Note: Use `no shutdown` for each ports after configured ip address, this will prevent the ports from shutting down.
:::

#### Step 2.2: Dynamic Routing Configuration (OSPF Multi-Area)

- ##### AREA-1

```bash
R-3>
R-3>en
R-3#conf t
R-3(config)#router ospf 1
R-3(config-router)#network 10.0.0.8 0.0.0.3 area 1
R-3(config-router)#network 192.168.1.0 0.0.0.255 area 1
R-3(config-router)#passive-interface Fa0/1
R-3(config-router)#exit

R-0>
R-0>en
R-0#conf t
R-0(config)#router ospf 1
R-0(config-router)#network 10.0.0.0 0.0.0.3 area 0
R-0(config-router)#network 10.0.0.8 0.0.0.3 area 1
```

- ##### AREA-2

```bash
R-4>
R-4>en
R-4#conf t
R-4(config)#router ospf 1
R-4(config-router)#network 10.0.0.12 0.0.0.3 area 2
R-4(config-router)#network 192.168.2.0 0.0.0.255 area 2
R-4(config-router)#passive-interface Fa0/1
R-4(config-router)#exit

R-1>
R-1>en
R-1#conf t
R-1(config)#router ospf 1
R-1(config-router)#network 10.0.0.0 0.0.0.3 area 0
R-1(config-router)#network 10.0.0.4 0.0.0.3 area 0
R-1(config-router)#network 10.0.0.12 0.0.0.3 area 2
```

- ##### AREA-3

```bash
R-5>
R-5>en
R-5#conf t
R-5(config)#router ospf 1
R-5(config-router)#network 10.0.0.16 0.0.0.3 area 3
R-5(config-router)#network 192.168.3.0 0.0.0.255 area 3
R-5(config-router)#passive-interface Fa0/1
R-5(config-router)#exit

R-2>
R-2>en
R-2#conf t
R-2(config)#router ospf 1
R-2(config-router)#network 10.0.0.4 0.0.0.3 area 0
R-2(config-router)#network 10.0.0.16 0.0.0.3 area 3
```

::: tip
Configure Dynamic Routing with OSPF.

Note: Use `area <area_number>` for area-based routing, and `network <network_address> <wildcard_mask> area <area_number>` to specify which networks belong to each area and use `passive-interface <interface>` to avoid OSPF adjacency with external routers with area 0 for main area.
:::

## 4. Verification & Troubleshooting

**Key Command:**

- **Network Test:** `PC1: ping 192.168.3.2`, `PC3 ping 192.168.12`
- **Check 1:** Are ping destination working?
- **Check 2:** Are ping default gateway working?

## 5. My Personal Notes (The Oktanetflow Touch)

- **Difficulty:** Medium
- **Mistakes I Made:** Dynamic Routing is more complex than static, but easier to manage when nodes are added or removed.
- **Related Resources:**
  - [Dynamic Routing](/guide/layer-3/dynamic-routing)
  - [Dynamic Routing Basic](/ecosystem/cisco/labs/routers/lab-02-dynamic-routing-basic)
- **Downloads:**
  <ButtonVue variant="secondary" as="a" class="no-underline!" href="./assets/lab-dynamic-routing-intermediate/lab-dynamic-routing-intermediate-ospf-multiarea.pkt" download>
  lab-dynamic-routing-intermediate-ospf-multiarea.pkt(Full Config)
  </ButtonVue>
