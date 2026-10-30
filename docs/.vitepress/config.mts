import { defineConfig } from "vitepress";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  lang: "id-ID",
  title: "Oktanetflow",
  description: "Personal Knowledge Summary & Network Visualization",
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: false,
  srcExclude: ["**/templates/**"],

  locales: {
    root: { label: "Indonesia", lang: "id" },
    en: { label: "English", lang: "en" },
  },

  themeConfig: {
    search: { provider: "local" },
    logo: "/oktanetflow.png",
    siteTitle: "Oktanetflow",
    lastUpdated: {
      text: "Last Updated:",
      formatOptions: { dateStyle: "medium", timeStyle: "medium" },
    },

    // ─── NAV ─────────────────────────────────────────────────────────────
    nav: [
      {
        text: "Docs",
        activeMatch: "/guide/",
        items: [{ text: "Guide Overview", link: "/guide/introduction" }],
      },
      {
        text: "Ecosystem",
        activeMatch: "/ecosystem/",
        items: [
          { text: "Ecosystem Overview", link: "/ecosystem/index" },
          {
            text: "Device Based",
            items: [
              { text: "Cisco Mastery", link: "/ecosystem/cisco/index" },
              {
                text: "MikroTik Essentials",
                link: "/ecosystem/mikrotik/index",
              },
              { text: "Juniper Lab", link: "/ecosystem/juniper/index" },
              { text: "Ruijie Lab", link: "/ecosystem/ruijie/index" },
            ],
          },
        ],
      },
      {
        text: "Infra",
        activeMatch: "/infra/",
        items: [
          { text: "Infra Overview", link: "/infra/index" },
          {
            text: "Categories",
            items: [
              { text: "Linux & Shell", link: "/infra/linux/index" },
              { text: "Virtualization & Cloud", link: "/infra/vm/index" },
              { text: "Server Management", link: "/infra/server/index" },
              { text: "Hardware", link: "/infra/hardware/index" },
              { text: "Software & Utilities", link: "/infra/software/index" },
            ],
          },
        ],
      },
      {
        text: "Tools",
        activeMatch: "/tools/",
        items: [
          { text: "Tools Overview", link: "/tools/index" },
          {
            text: "Utilities",
            items: [
              { text: "VLSM Calculator", link: "/tools/vlsm" },
              { text: "RDP Wrapper", link: "/tools/rdp-wrapper" },
              { text: "Bootable USB Installer", link: "/tools/bootable-usb" },
            ],
          },
        ],
      },
      {
        text: "About",
        activeMatch: "/about/",
        items: [
          { text: "About Oktanetflow", link: "/about/index" },
          { text: "The Project", link: "/about/project" },
          { text: "Team", link: "/about/team" },
          { text: "Changelog", link: "/about/changelog" },
        ],
      },
    ],

    // ─── SIDEBAR ─────────────────────────────────────────────────────────
    sidebar: {
      "/guide/": [
        {
          text: "Getting Started",
          items: [{ text: "Introduction", link: "/guide/introduction" }],
        },
        {
          text: "Essentials",
          items: [
            { text: "TCP/UDP Concepts", link: "/guide/essentials/tcp-udp" },
          ],
        },
        {
          text: "Layer 2",
          items: [
            { text: "Switch Concepts", link: "/guide/layer-2/switch-concept" },
            { text: "VLANs", link: "/guide/layer-2/vlans" },
            { text: "STP (Spanning Tree)", link: "/guide/layer-2/stp" },
          ],
        },
        {
          text: "Layer 3",
          items: [
            { text: "Routing Concepts", link: "/guide/layer-3/routing" },
            { text: "Static Routing", link: "/guide/layer-3/static-routing" },
            { text: "Dynamic Routing", link: "/guide/layer-3/dynamic-routing" },
          ],
        },
      ],

      "/ecosystem/": [
        {
          text: "Ecosystem Overview",
          items: [
            { text: "Overview", link: "/ecosystem/index" },
            { text: "Cisco Mastery", link: "/ecosystem/cisco/index" },
            { text: "MikroTik Essentials", link: "/ecosystem/mikrotik/index" },
            { text: "Juniper Lab", link: "/ecosystem/juniper/index" },
            { text: "Ruijie Lab", link: "/ecosystem/ruijie/index" },
          ],
        },
      ],

      "/ecosystem/cisco/": [
        {
          text: "Cisco Mastery",
          collapsed: false,
          items: [{ text: "Introduction", link: "/ecosystem/cisco/index" }],
        },
        {
          base: "/ecosystem/cisco/labs/",
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "Switches",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar Switch",
                  link: "switch/lab-01-basic-switch",
                },
              ],
            },
            {
              text: "VLANs",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar VLAN & Trunking",
                  link: "vlan/lab-01-basic-vlan-trunking",
                },
                {
                  text: "Lab 02: Dasar VLAN ROAS",
                  link: "vlan/lab-02-vlan-roas",
                },
              ],
            },
            {
              text: "Routers",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "routers/lab-01-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "routers/lab-02-dynamic-routing-basic",
                },
                {
                  text: "Lab 03: Dynamic Routing Intermediate",
                  link: "routers/lab-03-dynamic-routing-intermediate",
                },
                {
                  text: "Lab 04: Dynamic-Static Routing Basic",
                  link: "routers/lab-04-dynamic-static-routing-basic",
                },
              ],
            },
          ],
        },
      ],

      "/ecosystem/mikrotik/": [
        {
          text: "MikroTik Essentials",
          collapsed: false,
          items: [{ text: "Introduction", link: "/ecosystem/mikrotik/index" }],
        },
        {
          base: "/ecosystem/mikrotik/labs/",
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "Capstone",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar Capstone (VLAN, OSPF, DHCP, etc.)",
                  link: "capstone/lab-01-basic-capstone",
                },
              ],
            },
            {
              text: "VLANs",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar VLAN & Trunking",
                  link: "vlan/lab-01-basic-vlan-trunking",
                },
              ],
            },
            {
              text: "Routers",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "routers/lab-01-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "routers/lab-02-dynamic-routing-basic",
                },
              ],
            },
          ],
        },
      ],

      "/ecosystem/juniper/": [
        {
          text: "Juniper Lab",
          collapsed: false,
          items: [{ text: "Introduction", link: "/ecosystem/juniper/index" }],
        },
        {
          base: "/ecosystem/juniper/labs/",
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "VLANs",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar VLAN & Trunking",
                  link: "vlan/lab-01-basic-vlan-trunking",
                },
              ],
            },
          ],
        },
      ],

      "/ecosystem/ruijie/": [
        {
          text: "Ruijie Lab",
          collapsed: false,
          items: [{ text: "Introduction", link: "/ecosystem/ruijie/index" }],
        },
        {
          base: "/ecosystem/ruijie/labs/",
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "VLANs",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Dasar VLAN & Trunking",
                  link: "vlan/lab-01-basic-vlan-trunking",
                },
              ],
            },
          ],
        },
      ],

      "/infra/": [
        {
          text: "Infrastructure Overview",
          items: [
            { text: "Overview", link: "/infra/index" },
            { text: "Linux & Shell", link: "/infra/linux/index" },
            { text: "Virtualization & Cloud", link: "/infra/vm/index" },
            { text: "Server Management", link: "/infra/server/index" },
            { text: "Hardware", link: "/infra/hardware/index" },
            { text: "Software & Utilities", link: "/infra/software/index" },
          ],
        },
      ],

      "/infra/linux/": [
        {
          text: "Linux & Shell",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/linux/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          items: [
            {
              text: "Bash",
              collapsed: false,
              items: [
                {
                  text: "Bash Overview",
                  link: "/infra/linux/labs/bash/index",
                },
                {
                  text: "Lab 01: Quick VM Create in Proxmox",
                  link: "/infra/linux/labs/bash/lab-01-quick-vm-create-in-proxmox",
                },
                {
                  text: "Lab 02: Web Latency Profiler",
                  link: "/infra/linux/labs/bash/lab-02-bash-scripting-web-latency-profiler",
                },
                {
                  text: "Proxmox Bash",
                  collapsed: false,
                  items: [
                    {
                      text: "Proxmox Bash Overview",
                      link: "/infra/linux/labs/bash/proxmox-bash/index",
                    },
                    {
                      text: "Lab 01: Quick Server Specs Scanning",
                      link: "/infra/linux/labs/bash/proxmox-bash/lab-01-quick-proxmox-server-specs-scanning",
                    },
                    {
                      text: "Lab 02: Quick Pull Backup",
                      link: "/infra/linux/labs/bash/proxmox-bash/lab-02-quick-proxmox-pull-backup",
                    },
                  ],
                },
              ],
            },
            {
              text: "SSH",
              collapsed: false,
              items: [
                {
                  text: "SSH Setup",
                  link: "/infra/linux/labs/ssh/index",
                },
              ],
            },
            {
              text: "Ubuntu Server",
              collapsed: false,
              items: [
                {
                  text: "Ubuntu Overview",
                  link: "/infra/linux/labs/ubuntu/index",
                },
                {
                  text: "Lab 01: Config for Oldest Hardware",
                  link: "/infra/linux/labs/ubuntu/lab-01-quick-ubuntu-2404-configuration-for-oldest-hardware",
                },
                {
                  text: "Lab 02: Change Root Password",
                  link: "/infra/linux/labs/ubuntu/lab-02-change-root-password",
                },
                {
                  text: "Lab 03: Change Network & Nameserver",
                  link: "/infra/linux/labs/ubuntu/lab-03-change-network-and-nameserver",
                },
              ],
            },
          ],
        },
      ],

      "/infra/vm/": [
        {
          text: "Virtualization & Cloud",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/vm/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          base: "/infra/vm/labs/",
          items: [
            {
              text: "Proxmox",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: MikroTik on Proxmox",
                  link: "proxmox/lab-01-mikrotik-on-proxmox",
                },
                {
                  text: "Lab 02: Ubuntu Cloud on Proxmox",
                  link: "proxmox/lab-02-ubuntu-cloud-on-proxmox",
                },
                {
                  text: "Lab 03: AlmaLinux Network Setup",
                  link: "proxmox/lab-03-almalinux-network-setup",
                },
              ],
            },
            {
              text: "Proxmox Automation",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Backup Monitoring",
                  link: "proxmox-automation/lab-01-proxmox-automation-backup-monitoring",
                },
              ],
            },
          ],
        },
      ],

      "/infra/server/": [
        {
          text: "Server Management",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/server/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          base: "/infra/server/labs/",
          items: [
            {
              text: "Dell PowerEdge R620/R630",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Quick Setup Network & Proxmox",
                  link: "dell-r620-r630/lab-01-quick-setup-network-and-proxmox",
                },
                {
                  text: "Lab 02: Quick Setup Debian ISO",
                  link: "dell-r620-r630/lab-02-quick-setup-debian-iso",
                },
                {
                  text: "Lab 03: Initialize Storage SSD/SATA",
                  link: "dell-r620-r630/lab-03-initialize-storage-ssd-sata",
                },
              ],
            },
          ],
        },
      ],

      "/infra/hardware/": [
        {
          text: "Hardware",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/hardware/index" }],
        },
      ],

      "/infra/software/": [
        {
          text: "Software",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/software/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          base: "/infra/software/labs/",
          items: [
            {
              text: "Microsoft Office",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Quick Setup Microsoft Office",
                  link: "microsoft-office/lab-01-quick-setup-microsoft-office",
                },
              ],
            },
            {
              text: "Conversion Partition",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Quick Setup Conversion Partition",
                  link: "conversion-partition/lab-01-quick-setup-conversion-partition",
                },
              ],
            },
            {
              text: "Open VPN",
              collapsed: false,
              items: [
                {
                  text: "Lab 01: Quick Setup Open VPN",
                  link: "open-vpn/lab-01-quick-setup-open-vpn",
                },
              ],
            },
            {
              text: "SPSS & AMOS",
              collapsed: false,
              items: [
                {
                  text: "Overview",
                  link: "spss-amos-crack/index",
                },
                {
                  text: "Lab 01: Quick Setup SPSS & AMOS",
                  link: "spss-amos-crack/lab-01-quick-setup-spss-amos",
                },
              ],
            },
          ],
        },
      ],

      "/tools/": [
        {
          text: "Tools & Utilities",
          collapsed: false,
          items: [
            { text: "Overview", link: "/tools/index" },
            { text: "VLSM Calculator", link: "/tools/vlsm" },
            { text: "RDP Wrapper", link: "/tools/rdp-wrapper" },
            { text: "Bootable USB Installer", link: "/tools/bootable-usb" },
          ],
        },
      ],

      "/about/": [
        {
          text: "About Oktanetflow",
          collapsed: false,
          items: [
            { text: "Overview", link: "/about/index" },
            { text: "The Project", link: "/about/project" },
            { text: "Team", link: "/about/team" },
            { text: "Changelog", link: "/about/changelog" },
          ],
        },
      ],
    },

    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Dimas-oktavian17/oktanetflow",
      },
    ],

    footer: {
      message: "Beta Version",
      copyright: `Copyright © ${new Date().getFullYear()} Oktanetflow`,
    },
  },

  vite: {
    plugins: [tailwindcss()],
    resolve: {
      alias: { "@": fileURLToPath(new URL("../", import.meta.url)) },
    },
  },
});
