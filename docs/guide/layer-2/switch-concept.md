---
outline: deep
---

# Switch Concept <Badge type="tip" text="beta" />

## Switch

### 1. Konsep & Analogi
::: info Definisi Singkat
Switch adalah perangkat jaringan yang menghubungkan beberapa perangkat jaringan.
:::

* **Analogi:** Ibarat seorang kurir menggirimkan paket, berdasarkan data informasi yang unik dan ekslusif.
* **Karakteristik Utama:**
    * MAC Address Learning & Forwarding (Menyimpan alamat MAC dan mengirimkannya).
    * Collision Domain (Setiap port memiliki jalur yang ekslusif).
    * Sclable, Widely Used, Fast (Skalabel, sering digunakan, cepat).

### 2. Anatomi Header

*Fokus pada bagian penting:*
1.  **Destination Address (6 bytes):** Nomor MAC perangkat tujuan.
2.  **Source Address (6 bytes):** Nomor MAC perangkat sumber.
3.  **Preamble (7 bytes):** Untuk menandakan frame akan datang serta memberikan informasi kepada penerima.

### 3. Mekanisme Kerja (Mermaid Diagram)
Bagaimana topology switch menghubungkan perangkat jaringan?


```mermaid
graph TD
    %% Global Style
    classDef switch fill:#2d3436,color:#fff,stroke:#000,stroke-width:2px;
    classDef pc fill:#BBwBwB,stroke:#636e72,stroke-width:1px;
    classDef domain fill:#bd3f32,stroke:#fff,stroke-dasharray: 5 5;

    subgraph Switch_Unit [Network Switch - Layer 2]
        SW((Switch Core))
    end

    %% Collision Domain 1
    subgraph CD1 [Collision Domain 1]
        PC1[PC-A <br/> MAC: 00:AA:11]
    end

    %% Collision Domain 2
    subgraph CD2 [Collision Domain 2]
        PC2[PC-B <br/> MAC: 00:BB:22]
    end

    %% Collision Domain 3
    subgraph CD3 [Collision Domain 3]
        PC3[PC-C <br/> MAC: 00:CC:33]
    end

    %% Connections
    PC1 ---|Port 1| SW
    PC2 ---|Port 2| SW
    PC3 ---|Port 3| SW

    %% Labels
    class SW switch;
    class PC1,PC2,PC3 pc;
    class CD1,CD2,CD3 domain;
```

### 4. Network Labs: Implementation & Hands-on

#### Cisco Mastery
* **Cisco**: [Lab 01: Dasar Switch](../../ecosystem/cisco/labs/switch/lab-01-basic-switch.md).

::: tip Multi Vendor Coming soons
More content coming soon! We are still focusing on Cisco Mastery. Check back later for updates.
