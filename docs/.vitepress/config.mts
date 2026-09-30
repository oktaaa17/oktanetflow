import { defineConfig } from "vitepress";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  lang: "id-ID",
  title: "Oktanetflow",
  description: "Personal Knowledge Summary & Network Visualization",
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: true,

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

    // â”€â”€â”€ NAV â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    nav: [
      {
        text: "Docs",
        activeMatch: "/guide/",
        items: [{ text: "Guide", link: "/guide/introduction" }],
      },
      {
        text: "Ecosystem",
        activeMatch: "/ecosystem/",
        items: [
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
        text: "Infra", // â† NEW
        activeMatch: "/infra/",
        items: [
          {
            text: "Linux & Shell",
            items: [
              { text: "Linux Overview", link: "/infra/linux/index" },
              { text: "Bash", link: "/infra/linux/labs/bash/" },
              { text: "SSH", link: "/infra/linux/labs/ssh/" },
              {
                text: "Ubuntu",
                link: "/infra/linux/labs/ubuntu/lab-01-quick-ubuntu-2404-configuration-for-oldest-hardware",
              },
            ],
          },
          {
            text: "Virtualization",
            items: [
              { text: "VM Overview", link: "/infra/vm/index" },
              {
                text: "Proxmox: MikroTik",
                link: "/infra/vm/labs/proxmox/mikrotik-on-proxmox",
              },
              {
                text: "Proxmox: Ubuntu Cloud",
                link: "/infra/vm/labs/proxmox/ubuntu-cloud-on-proxmox",
              },
              {
                text: "Proxmox: AlmaLinux Network Setup",
                link: "/infra/vm/labs/proxmox/almalinux-network-setup",
              },
            ],
          },
          {
            text: "Server",
            items: [{ text: "Server Overview", link: "/infra/server/index" }],
          },
          {
            text: "Hardware",
            items: [
              { text: "Hardware Overview", link: "/infra/hardware/index" },
            ],
          },
          {
            text: "Software",
            items: [
              { text: "Software Overview", link: "/infra/software/index" },
              {
                text: "SPSS & AMOS",
                link: "/infra/software/labs/spss-amos-crack/",
              },
            ],
          },
        ],
      },
      {
        text: "Tools",
        items: [
          { text: "VLSM Calculator", link: "/tools/vlsm" },
          { text: "RDP Wrapper", link: "/tools/rdp-wrapper" }, // â† refactored
          { text: "Bootable USB Installer", link: "/tools/bootable-usb" }, // â† refactored
        ],
      },
      {
        text: "About",
        items: [
          { text: "The Project", link: "/about/project" },
          { text: "Team", link: "/about/team" },
          { text: "Changelog", link: "/about/changelog" },
        ],
      },
    ],

    // â”€â”€â”€ SIDEBAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    sidebar: {
      "/guide/": [
        {
          text: "Getting Started",
          items: [{ text: "Introduction", link: "/guide/introduction" }],
        },
        {
          text: "Essential",
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
          items: [
            {
              text: "Switches",
              items: [
                {
                  text: "Lab 01: Dasar Switch",
                  link: "/switch/lab-switch-dasar",
                },
              ],
            },
            {
              text: "VLANs",
              items: [
                {
                  text: "Lab 01: Dasar VLAN & Trunking",
                  link: "/vlan/lab-vlan-dasar-trunking",
                },
                {
                  text: "Lab 02: VLAN ROAS",
                  link: "/vlan/lab-vlan-dasar-roas",
                },
              ],
            },
            {
              text: "STP (Spanning Tree Protocol)",
              items: [],
            },
            {
              text: "Routers",
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "/routers/lab-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "/routers/lab-dynamic-routing-basic",
                },
                {
                  text: "Lab 03: Dynamic Routing Intermediate",
                  link: "/routers/lab-dynamic-routing-intermediate",
                },
                {
                  text: "Lab 04: Dynamic Routing Advanced",
                  link: "/routers/lab-dynamic-routing-advanced",
                },
                {
                  text: "Lab 05: Dynamic-Static Routing Basic",
                  link: "/routers/lab-dynamic-static-routing-basic",
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
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "Capstone",
              items: [
                {
                  text: "Lab 01: Dasar Capstone (VLAN, OSPF, DHCP, etc.)",
                  link: "/ecosystem/mikrotik/labs/capstone/lab-dasar-capstone",
                },
              ],
            },
            {
              text: "Routers",
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "/ecosystem/mikrotik/labs/routers/lab-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "/ecosystem/mikrotik/labs/routers/lab-dynamic-routing-basic",
                },
                {
                  text: "Lab 04: Dynamic Routing Intermediate",
                  link: "/ecosystem/mikrotik/labs/routers/lab-dynamic-routing-intermediate",
                },
                {
                  text: "Lab 03: Dynamic Routing Advanced",
                  link: "/ecosystem/mikrotik/labs/routers/lab-dynamic-routing-advanced",
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
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "Routers",
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "/ecosystem/ruijie/labs/routers/lab-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-basic",
                },
                {
                  text: "Lab 04: Dynamic Routing Intermediate",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-intermediate",
                },
                {
                  text: "Lab 03: Dynamic Routing Advanced",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-advanced",
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
          text: "Network Labs",
          collapsed: false,
          items: [
            {
              text: "Routers",
              items: [
                {
                  text: "Lab 01: Static Routing Basics",
                  link: "/ecosystem/ruijie/labs/routers/lab-static-routing",
                },
                {
                  text: "Lab 02: Dynamic Routing Basic",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-basic",
                },
                {
                  text: "Lab 04: Dynamic Routing Intermediate",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-intermediate",
                },
                {
                  text: "Lab 03: Dynamic Routing Advanced",
                  link: "/ecosystem/ruijie/labs/routers/lab-dynamic-routing-advanced",
                },
              ],
            },
          ],
        },
      ],

      // â”€â”€ INFRA (new) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      "/infra/": [
        {
          text: "Infra Overview",
          items: [
            { text: "Linux & Shell", link: "/infra/linux/index" },
            { text: "VM / Proxmox", link: "/infra/vm/index" },
            { text: "Server", link: "/infra/server/index" },
            { text: "Hardware", link: "/infra/hardware/index" },
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
              items: [
                {
                  text: "Lab 01: Quick VM Create in Proxmox",
                  link: "/infra/linux/labs/bash/lab-01-quick-vm-create-in-proxmox",
                },
              ],
            },
            {
              text: "SSH",
              items: [
                // { text: "Lab 01: ...", link: "/infra/linux/labs/ssh/lab-01" },
              ],
            },
            {
              text: "Ubuntu",
              items: [
                {
                  text: "Lab 01: Quick ubuntu 24.04 configuration for oldest hardware",
                  link: "/infra/linux/labs/ubuntu/lab-01-quick-ubuntu-2404-configuration-for-oldest-hardware",
                },
                {
                  text: "Lab 02: Change Root Password",
                  link: "/infra/linux/labs/ubuntu/lab-02-change-root-password",
                },
                {
                  text: "Lab 03: Change Network and Nameserver",
                  link: "/infra/linux/labs/ubuntu/lab-03-change-network-and-nameserver",
                },
              ],
            },
          ],
        },
      ],

      "/infra/vm/": [
        {
          text: "Virtualization",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/vm/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          items: [
            {
              text: "Proxmox",
              items: [
                {
                  text: "MikroTik on Proxmox",
                  link: "/infra/vm/labs/proxmox/mikrotik-on-proxmox",
                },
                {
                  text: "Ubuntu Cloud on Proxmox",
                  link: "/infra/vm/labs/proxmox/ubuntu-cloud-on-proxmox",
                },
                {
                  text: "AlmaLinux Network Setup",
                  link: "/infra/vm/labs/proxmox/almalinux-network-setup",
                },
              ],
            },
            {
              text: "Proxmox Automation",
              items: [
                {
                  text: "Proxmox Automation Backup Monitoring",
                  link: "/infra/vm/labs/proxmox-automation/proxmox-automation-backup-monitoring",
                },
              ],
            },
          ],
        },
      ],

      "/infra/server/": [
        {
          text: "Server",
          collapsed: false,
          items: [{ text: "Overview", link: "/infra/server/index" }],
        },
        {
          text: "Labs",
          collapsed: false,
          items: [
            {
              text: "server dell r620/r630",
              items: [
                {
                  text: "Lab 01: Quick setup network and proxmox",
                  link: "/infra/server/labs/dell-r620-r630/lab-01",
                },
                {
                  text: "Lab 02: Quick setup debian iso",
                  link: "/infra/server/labs/dell-r620-r630/lab-02",
                },
                {
                  text: "Lab 03: Initialize storage SSD/SATA",
                  link: "/infra/server/labs/dell-r620-r630/lab-03-initialize-storage-ssd-sata",
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
        { text: "Labs", collapsed: false, items: [] },
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
          items: [
            {
              text: "Microsoft Office",
              items: [
                {
                  text: "Lab 01: Quick setup Microsoft Office",
                  link: "/infra/software/labs/microsoft-office/lab-01-quick-setup-microsoft-office",
                },
              ],
            },
            {
              text: "Conversion Partition",
              items: [
                {
                  text: "Lab 02: Quick setup conversion partition",
                  link: "/infra/software/labs/conversion-partition/lab-01-quick-setup-conversion-partition",
                },
              ],
            },
            {
              text: "Open VPN",
              items: [
                {
                  text: "Lab 01: Quick setup Open VPN",
                  link: "/infra/software/labs/open-vpn/lab-01-quick-setup-open-vpn",
                },
              ],
            },
            {
              text: "SPSS & AMOS",
              items: [
                {
                  text: "Lab 01: Quick setup SPSS & AMOS",
                  link: "/infra/software/labs/spss-amos-crack/lab-01-quick-setup-spss-amos",
                },
              ],
            },
          ],
        },
      ],
      // â”€â”€ TOOLS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      "/tools/": [
        {
          text: "Interactive Tools",
          items: [
            { text: "VLSM Calculator", link: "/tools/vlsm" },
            { text: "RDP Wrapper", link: "/tools/rdp-wrapper" }, // â† refactored
            { text: "Bootable USB Installer", link: "/tools/bootable-usb" }, // â† refactored
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
      copyright: `Copyright Â© ${new Date().getFullYear()} Oktanetflow`,
    },
  },

  vite: {
    plugins: [tailwindcss()],
    resolve: {
      alias: { "@": fileURLToPath(new URL("../", import.meta.url)) },
    },
  },
});
