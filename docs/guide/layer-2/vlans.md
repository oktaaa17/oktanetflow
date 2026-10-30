---
outline: deep
---

# VLANs Concept <Badge type="tip" text="beta" />

## VLANs

### 1. Konsep & Analogi
::: info Definisi Singkat
VLAN(Virtual Local Area Network) adalah teknologi pada switch yang memungkinkan isolasi jaringan dalam perangkat yang sama.
:::

* **Analogi:** Kantor tanpa ruang kerja tiap departemen.

    Bayangkan sebuah kantor tanpa ruang kerja tiap departemen. Apabila seseorang departemen A berdiskusi, maka seluruh departemen lain akan mendengar. Akan berbeda jika mereka berdiskusi di ruang kerja masing-masing`(VLAN)`.

* **Karakteristik Utama:**
    * Broadcast Domain Segmentation (Membuat unik broadcast domain). 
    * Logical Isolation (Pengguna dan device dikelompokkan dalam VLAN).
    * Enchanced Security and Performance (Meningkatkan keamanan dan performa, tanpa perlu menggirimkan broadcast traffic yang tidak diperlukan).

::: info
By default, Switch has single Broadcast Domain. With Frame flooding mechanism, will be broadcasted to all active ports.
:::

### 2. Anatomi Header IEEE 802.1Q VLAN Tagging

*Fokus pada bagian penting:*
1.  **Tag Protocol Identifier(TPID) (2 bytes):** Identifikasi 802.1Q tagged frame.
2.  **Tag Control Information(TCI) (2 bytes):** Identifikasi Informasi kontrol->(Priority,DEI(Drop Eligible Indicator), VID(VLAN ID)).


### 3. Mekanisme Kerja (Mermaid Diagram)
Bagaimana VLANs bekerja dalam switch?


```mermaid
graph LR
    %% Global Style
    classDef switch fill:#2d3436,color:#fff,stroke:#000,stroke-width:2px;
    classDef vlanActive fill:#2ecc71,color:#fff,stroke:#27ae60,stroke-width:2px;
    classDef vlanInactive fill:#2d3436,color:#636e72,stroke:#000,stroke-width:1px,stroke-dasharray: 5 5;
    classDef source fill:#e67e22,color:#fff,stroke:#d35400,stroke-width:3px;

    %% Source di Kiri
    SRC((Incoming <br/> Broadcast <br/> VLAN 20)) --- SW

    subgraph Cisco_Switch [Cisco Switch - Layer 2]
        direction LR
      
        SW((Switch <br/> Core))
        
        %% Grup Port Aktif
        subgraph G1 [VLAN 20 Segment]
            direction TB
            P_ACT[Port 1-6 <br/> STATUS: ACTIVE]
        end

        %% Grup Port Inaktif
        subgraph G2 [VLAN 10 Segment]
            direction TB
            P_BLK[Port 7-12 <br/> STATUS: INACTIVED]
        end
    end

    %% Jalur Data
    SW ===|Forwarding| P_ACT
    SW -.-|Filtered| P_BLK

    %% Styling
    class SW switch
    class SRC source
    class P_ACT vlanActive
    class P_BLK vlanInactive

    %% Manual Link Colors
    linkStyle 0 stroke:#e67e22,stroke-width:4px
    linkStyle 1 stroke:#2ecc71,stroke-width:4px
    linkStyle 2 stroke:#000,stroke-width:1px,opacity:0.3
```

### 4. Network Labs: Implementation & Hands-on

#### Cisco Mastery
* **Cisco**: [Lab 01: Dasar VLAN & Trunking](../../ecosystem/cisco/labs/vlan/lab-01-basic-vlan-trunking.md).
* **MikroTik**: [Lab 01: Dasar VLAN & Trunking](../../ecosystem/mikrotik/labs/vlan/lab-01-basic-vlan-trunking.md).
* **Juniper**: [Lab 01: Dasar VLAN & Trunking](../../ecosystem/juniper/labs/vlan/lab-01-basic-vlan-trunking.md).
* **Ruijie**: [Lab 01: Dasar VLAN & Trunking](../../ecosystem/ruijie/labs/vlan/lab-01-basic-vlan-trunking.md).

::: tip Multi Vendor Coming soons
More content coming soon! We are still focusing on Cisco Mastery. Check back later for updates.
