---
outline: deep
head:
  - - meta
    - name: description
      content: "Panduan lengkap sshm oleh Oktanetflow: CLI/TUI SSH Client minimalis & agile untuk Windows dengan Windows Credential Manager, Split-Pane Inspector, live latency probe, dan EXE Installer."
  - - meta
    - name: keywords
      content: "sshm, SSH Client Windows, TUI SSH Manager, Go SSH Client, Windows Credential Manager, Port Forwarding, SFTP, Oktanetflow"
  - - meta
    - name: author
      content: "Oktanetflow"
  - - meta
    - property: "og:title"
      content: "Tools Guide: sshm — Agile CLI/TUI SSH Client for Windows - Oktanetflow"
  - - meta
    - property: "og:description"
      content: "SSH client & server manager single-binary berbahasa Go untuk Windows dengan penyimpanan password aman, live TCP probe, port forwarding, dan Windows EXE Installer."
  - - meta
    - property: "og:type"
      content: "article"
  - - meta
    - name: "twitter:card"
      content: "summary"
  - - meta
    - name: "twitter:title"
      content: "sshm — Agile CLI/TUI SSH Client for Windows - Oktanetflow"
  - - link
    - rel: canonical
      href: "https://oktanetflow.vercel.app/tools/sshm"
---

# Tools Guide: sshm — Agile CLI/TUI SSH Client for Windows

<Badge type="tip" text="v1.0.0" /> <Badge type="info" text="Windows 10 / 11" /> <Badge type="info" text="Pure Go · Zero Dependencies" />

**`sshm`** adalah CLI/TUI SSH Client dan Server Manager single-binary yang dikembangkan secara independen oleh **Oktanetflow** khusus untuk alur kerja cepat di **Windows 10/11** (Windows Terminal, PowerShell 5.1/7+, CMD, VS Code) tanpa ketergantungan eksternal (tanpa PuTTY, WSL, Cygwin, OpenSSH binary, atau `sshpass`).

::: info Proyek Independen (Bukan Clone `gu1llaum-3/sshm`)
`sshm` oleh Oktanetflow ditulis dari nol dalam bahasa **Go (`CGO_ENABLED=0`)** menggunakan stack native `golang.org/x/crypto/ssh`, `pkg/sftp`, Win32 VT100 Console API, dan Windows Credential Manager — berbeda arsitektur dengan `gu1llaum-3/sshm` yang membungkus binary OpenSSH lokal.
:::

---

## 1. Fitur Utama

- **Agile Interactive TUI (`sshm`):**
  - **Split-Pane Host & Group Inspector (`i`):** Menampilkan endpoint efektif, group defaults yang diwariskan, auth backend, jump host, status TCP live, `#tags`, port forward, catatan (`notes`), dan waktu koneksi terakhir.
  - **Live Async TCP Reachability & Latency Probe (`r`):** Worker pool non-blocking menampilkan indikator `● 14ms` / `● off` serta ringkasan jumlah host online pada header.
  - **Interactive Port Forward Manager (`f`):** Tambah dan hapus tunnel Local (`-L`), Remote (`-R`), dan Dynamic SOCKS5 (`-D`) langsung dari dalam TUI.
  - **Quick Theme Switcher (`t`):** Berpindah tema `minimal-dark`, `minimal-light`, dan `mono` secara instan.
  - **Collapsible Server Groups & Fuzzy Search (`/`):** Kelompokkan server (`prod`, `staging`, `personal`) dengan badge warna dan default `user`, `port`, `key`, serta `jump` yang diwariskan.
- **Keamanan Kredensial Tanpa Plaintext:**
  - **Save Password by Default (`save_password_by_default = true`):** Password tidak pernah ditulis ke `hosts.toml` dan disimpan otomatis melalui **Windows Credential Manager**, **Windows DPAPI**, atau **Encrypted Vault (`Argon2id` + `AES-256-GCM`)**.
  - **Windows NTFS Owner-Only ACL:** Direktori `%APPDATA%\sshm\` dikunci dengan Win32 DACL hanya untuk user Windows aktif dan `SYSTEM`.
  - **Memory Hygiene:** Buffer password dan blob DPAPI di-zeroing secara eksplisit setelah autentikasi.
- **Power Features Bawaan:**
  - `ProxyJump` antar alias, SFTP copy (`sshm cp`), eksekusi paralel satu grup (`sshm exec @prod "uptime" --parallel`), impor `~/.ssh/config` & PuTTY Registry, backup terenkripsi `.sshm.enc`, dan PowerShell tab completion.

---

## 2. Instalasi di Windows

### Opsi 1: Windows EXE Installer (Direkomendasikan)

1. Unduh **`sshm-setup-1.0.0-amd64.exe`** beserta **`SHA256SUMS.txt`** dari repository rilis:
   [GitHub Releases — oktaaa17/sshm](https://github.com/oktaaa17/sshm/releases)
2. Verifikasi integritas file di PowerShell sebelum menjalankan installer:

```powershell
Get-FileHash .\sshm-setup-1.0.0-amd64.exe -Algorithm SHA256
```

3. Jalankan `sshm-setup-1.0.0-amd64.exe`.
   Installer berbasis **Inno Setup 6** berjalan per-user (`PrivilegesRequired=lowest`, tanpa prompt UAC Administrator), menginstal ke `%LOCALAPPDATA%\Programs\Oktanetflow\sshm`, mendaftarkan `sshm` ke **User PATH**, dan menyediakan uninstaller bersih.

### Opsi 2: Build dari Source Code

```powershell
git clone https://github.com/oktaaa17/sshm.git
cd sshm
powershell -ExecutionPolicy Bypass -File scripts/build-release.ps1 -Version 1.0.0
```

### Aktifkan Autocomplete PowerShell (Opsional)

Tambahkan baris berikut ke `$PROFILE` PowerShell Anda:

```powershell
sshm completion powershell | Out-String | Invoke-Expression
```

---

## 3. Tampilan TUI & Keybindings

```text
 sshm v1.0.0  5 hosts · 2 groups · 4 online       [?] Help [a] Add [g] Group [t] Theme [r] Probe [q] Quit
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
 > search: _                                               [All] prod  staging

 ▼ prod (3)                                          │ Host — prod-api-01
   ●★ prod-api-01   root@10.0.1.12  [pw]  ● 14ms ⇄1  │ ──────────────────────────────────────────────
   ●  prod-api-02   root@10.0.1.13  [key] ● 22ms     │ Endpoint : root@10.0.1.12:22
   ●  prod-db-01    pg@10.0.1.20    [pw]  ● 31ms     │ Group    : ● prod  ★ Pinned
                                                     │ Auth     : password (Windows Credential Mgr)
 ▼ staging (2)                                       │ Jump     : via bastion-prod (inherited)
   ●  stg-web       ubuntu@10.0.2.5 [pw]  ● 45ms     │ Status   : ● Online (14ms TCP)
   ●  stg-worker    ubuntu@10.0.2.6 [pw]  ● off      │ Tags     : #api #linux
                                                     │ Tunnels  : 1 configured ([f] edit)
                                                     │   L 127.0.0.1:8080 -> 127.0.0.1:80
                                                     │ Notes    : Primary production API node
                                                     │ Last Seen: 2m ago
 ────────────────────────────────────────────────────────────────────────────────────────────────────────
 [Enter] Connect [Tab] Group [/] Search [i] Inspector [e] Edit [f] Forwards [d] Delete [p] Pin
 Copyright © 2026 Oktanetflow                          Theme: minimal-dark · Store: Windows Credential Manager
```

| Tombol | Fungsi |
| :--- | :--- |
| `↑` / `↓` atau `j` / `k` | Navigasi daftar host dan grup |
| `Enter` | Koneksi ke host terpilih (atau buka/tutup grup) |
| `/` | Fuzzy search (alias, IP, user, grup, jump, tags, notes) |
| `Tab` / `Shift+Tab` | Ganti tab filter grup |
| `Space` / `←` / `→` | Lipat / buka grup |
| `i` | Toggle **Split-Pane Host Inspector** (aktif otomatis pada lebar ≥ 100 kolom) |
| `r` | Refresh **live TCP reachability & latency probe** |
| `t` | Ganti tema UI (`minimal-dark` / `minimal-light` / `mono`) |
| `a` / `e` / `d` | Tambah / edit / hapus host beserta kredensial tersimpan |
| `f` | Kelola **Port Forwards** (`-L`, `-R`, `-D`) untuk host terpilih |
| `p` | Pin / unpin host ke bagian atas grup |
| `g` | Buat atau ubah grup & inherited defaults |
| `?` / `q` | Bantuan / Keluar |

---

## 4. Perintah CLI Harian

```powershell
# Buka interactive TUI
sshm

# Koneksi cepat via alias atau ad-hoc (mendukung IPv4 & bracketed IPv6)
sshm prod-api
sshm ubuntu@[2001:db8::1]:2222

# Tambah host dan grup dengan inherited defaults
sshm group create prod --color red --default-user root --default-port 22
sshm add prod-api --host 10.0.1.12 --user root --group prod --tags api,linux

# Port forwarding (-L local, -R remote, -D dynamic SOCKS5)
sshm prod-db -L 5432:127.0.0.1:5432
sshm prod-api -D 1080

# Eksekusi perintah paralel ke seluruh grup
sshm exec @prod "uptime" --parallel

# Transfer file via SFTP
sshm cp .\app.zip prod-api:/opt/app/
sshm cp prod-api:/var/log/app.log .\app.log

# Impor konfigurasi OpenSSH atau PuTTY Registry
sshm import --ssh-config
sshm import --putty

# Backup & restore terenkripsi (Argon2id + AES-256-GCM)
sshm export backup.sshm.enc
sshm import --backup backup.sshm.enc
```

---

## 5. Keamanan & Kompatibilitas Windows Security

::: tip Jangan Pernah Menonaktifkan Windows Defender atau SmartScreen
`sshm` dirancang agar dapat dijalankan secara aman dengan **Windows Security / Windows Defender tetap aktif**.
Binary dibangun secara reproducible (`CGO_ENABLED=0 -trimpath`), **tanpa UPX packer**, menyertakan Win32 PE VersionInfo (`Oktanetflow`) serta manifest `asInvoker`, dan telah lulus audit otomatis `go vet`, `govulncheck` (0 CVE), dan `gosec` (0 medium/high issues).
:::

Verifikasi metadata publisher dan signature binary langsung dari PowerShell:

```powershell
(Get-Item .\sshm.exe).VersionInfo | Format-List CompanyName, ProductName, ProductVersion, LegalCopyright
Get-AuthenticodeSignature .\sshm.exe
```

---

## 6. Referensi & Lisensi

- **Source Code & Releases:** [github.com/oktaaa17/sshm](https://github.com/oktaaa17/sshm)
- **Lisensi:** MIT License — **Copyright © 2026 Oktanetflow**
