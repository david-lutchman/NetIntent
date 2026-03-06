# NetIntent — Network Configuration Assistant

AI-powered desktop application for analyzing multi-vendor network configurations and generating precise CLI change scripts from plain English. Load your entire environment, visualize the topology, describe what you want, and export ready-to-paste commands — all processed locally with only redacted excerpts sent to the LLM.

> **Trial version** — this build includes a 7-day free trial. Contact [dlutchman@gmail.com](mailto:dlutchman@gmail.com) to continue after the trial period.

## Quick Start

1. Download `target/release/netintent.exe` from this repository
2. Double-click to launch — no installer required
3. Click the **gear icon** (top right) → choose an LLM provider → paste your API key → Save
4. Click **Load** to upload one or more device configs (`.cfg`, `.conf`, `.txt`, `.rsc`)
5. Check the devices you want to target in the sidebar
6. Click **Make Changes** → describe your intent in plain English → **Analyze**
7. Review the change plan → approve or reject individual changes
8. Click **View Topology** to see the projected network state after changes
9. **Export** scripts per device or all at once

**Requirement:** Windows 10 or 11 with [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) (pre-installed on Windows 10 21H2+ and all Windows 11)

## Supported Vendors

| Vendor | Format | Detection |
|--------|--------|-----------|
| **Cisco IOS / IOS-XE** | Block (`interface ... !`) | `hostname`, `ip address`, `version` |
| **Arista EOS** | Block (Cisco-like) | `management api http-commands`, `daemon TerminAttr` |
| **Juniper Junos** | Set-format or hierarchical | `set system host-name`, brace blocks |
| **Extreme EXOS** | Flat commands | `create vlan ... tag`, `ExtremeXOS` |
| **Fortinet FortiOS** | `config / end` blocks | `config system global`, `set hostname` |
| **MikroTik RouterOS** | `/section` hierarchy | `/system identity`, `/interface ethernet` |
| **HPE / Aruba** | Block (Cisco-like) | `HP ProCurve`, `tagged` port syntax |
| **Huawei VRP** | `#`-delimited blocks | `sysname`, `vlan batch` |
| **Nokia SR OS** | Flat `configure` commands | `configure system name`, `configure port` |

The parser scores config text against vendor-specific patterns and picks the highest-confidence match. All vendor parsing, topology inference, and secret redaction happen entirely on your machine.

## LLM Providers

| Provider | Key Required | Models |
|----------|-------------|--------|
| **Claude** (Anthropic) | Yes — [console.anthropic.com](https://console.anthropic.com) | Claude Sonnet 4.5, Claude Opus 4.5 |
| **Gemini** (Google) | Yes — [aistudio.google.com](https://aistudio.google.com/app/apikey) | Gemini 2.0 Flash, Gemini 2.5 Pro |
| **ChatGPT** (OpenAI) | Yes — [platform.openai.com](https://platform.openai.com/api-keys) | GPT-4o, GPT-4o mini, o1 |
| **Ollama** (local) | None | Any locally-pulled model (e.g. `llama3.2`) |

Responses stream token-by-token — you see the JSON being generated in real time rather than waiting for the full response.

## Features

### Multi-Vendor Config Parsing
Automatically detects the vendor OS from the config text, extracts hostname and version, and splits the running config into browsable sections: interfaces, VLANs, routing protocols, ACLs, line configs, crypto, QoS, and global commands. Filter by section type to quickly find what you need. If auto-detection is wrong, click the vendor badge in the sidebar to override it manually.

### Interactive Network Topology
An auto-generated network diagram built from your uploaded configs. The topology engine detects connections two ways: by matching interface descriptions that reference other device hostnames (e.g. `UPLINK-TO-DIST-SW01`), and by matching IP subnets across devices. The diagram supports:

- **Drag** to reposition devices (positions are preserved across restarts)
- **Scroll** to zoom, **drag background** to pan, **Fit** button to auto-frame
- **Port dots** along each device, color-coded by mode (blue = trunk, green = access, amber = routed, gray = shutdown)
- **Hover** any port for name, mode, VLAN, and allowed VLAN details
- **Connect mode** — manually link two ports across devices by clicking them
- **Delete links** — select a link and remove it
- **Port detail panel** — click the ℹ button on any device to see all interfaces, SVIs, IP addresses, and connections
- **Double-click** any device to jump to its config view

### Projected Topology (Before/After)
After generating a change plan, click **View Topology** or the Topology tab. A **Current / After Changes** toggle compares the network now versus after approved changes are applied:

- Green ring + **NEW** badge on added ports, VLANs, and links
- Amber ring + **MOD** badge on modified ports (mode changes, VLAN reassignment, trunk updates)
- Red dashed + **DEL** badge on removed or shutdown elements
- Devices with changes get a dashed teal border

The projection updates live — toggle changes on/off and the topology reflects it immediately.

### Secret Redaction
All passwords, enable secrets, SNMP communities, TACACS/RADIUS keys, BGP neighbor passwords, OSPF/EIGRP authentication keys, and crypto pre-shared keys are automatically stripped before anything is sent to the LLM. A redaction panel shows exactly what was found, with per-item reveal toggles.

### AI-Powered Change Generation (Streaming)
Describe your intent in plain English. The system extracts only the relevant config sections, redacts secrets, and sends them to your chosen LLM along with a structured system prompt that enforces vendor-correct CLI syntax, proper command hierarchy, impact assessment, and rollback generation. Supports single-device and coordinated multi-device changes.

Responses stream token-by-token — the raw JSON appears in the processing pane as it arrives, then is parsed and rendered as a structured plan when complete.

### Change Plan Review
Every generated change is individually approvable with full context: action type (add/modify/remove), affected section, reasoning, impact rating (low/medium/high), and the exact CLI commands. Copy individual command blocks to clipboard, view before/after diffs per section, and export per-device or environment-wide scripts with rollback commands included.

## Example Intents

**Single device:**
- "Add VLAN 100 named Marketing, assign Gi0/3 and Gi0/4 as access ports, and trunk it on all uplinks" *(Cisco)*
- "Configure OSPF area 0 on all Layer 3 interfaces with MD5 authentication" *(Cisco / Arista)*
- "Enable BFD on all OSPF interfaces with 300ms intervals and multiplier 3" *(Arista)*
- "Add a new VLAN 50 named Contractors with ID 50, create an IRB interface with IP 10.10.50.1/24" *(Juniper)*
- "Create a new address object for the IoT segment and add a firewall policy denying it access to the TRUST-LAN zone" *(Fortinet)*
- "Add a RADIUS server at 10.0.0.21 as a backup with key 'radiusbackup'" *(HPE/Aruba)*
- "Add OSPF authentication on GigabitEthernet0/0/0 using MD5" *(Huawei)*
- "Configure a BGP peer at 10.255.0.32 as an iBGP neighbor" *(Nokia)*

**Multi-device:**
- "Add VLAN 200 named Analytics across all switches and ensure all interswitch trunks allow it"
- "Standardize NTP to 10.0.0.10 as primary and 10.0.0.11 as secondary on every device"
- "Add a syslog server at 10.0.0.51 as a secondary log target on all devices"
- "Change the OSPF hello interval to 10 seconds and dead interval to 40 seconds on all OSPF devices"

**Adversarial (tests the LLM's guardrails):**
- "Delete VLAN 1" — should warn about native VLAN risk
- "Enable telnet on all VTY lines" — should flag as a security risk
- "Remove the OSPF configuration from the Nokia core gateway" — should warn about adjacency loss

## Sample Configs

Eighteen test configs are included in the `samples/` folder — two devices per vendor for multi-device testing:

| Files | Vendor | Hostnames |
|-------|--------|-----------|
| `cisco-core-sw01.cfg`, `cisco-dist-sw01.cfg` | Cisco IOS-XE | CISCO-CORE-SW01, CISCO-DIST-SW01 |
| `arista-core-sw01.cfg`, `arista-dist-sw02.cfg` | Arista EOS | ARISTA-CORE-SW01, ARISTA-DIST-SW02 |
| `juniper-core-gw01.conf`, `juniper-dist-sw01.conf` | Juniper Junos | juniper-core-gw01, juniper-dist-sw01 |
| `extreme-access-sw01.cfg`, `extreme-access-sw02.cfg` | Extreme EXOS | EXTREME-ACCESS-SW01, EXTREME-ACCESS-SW02 |
| `fortinet-hq-fw01.conf`, `fortinet-branch-fw02.conf` | Fortinet FortiOS | FW-HQ-01, FW-BRANCH-02 |
| `mikrotik-core-gw01.rsc`, `mikrotik-branch-gw01.rsc` | MikroTik RouterOS | MikroTik-Core-GW01, MikroTik-Branch-GW01 |
| `hpe-aruba-core-sw01.cfg`, `hpe-aruba-access-sw02.cfg` | HPE/Aruba | HPE-CORE-SW01, HPE-ACCESS-SW02 |
| `huawei-core-sw01.cfg`, `huawei-access-sw02.cfg` | Huawei VRP | HUAWEI-CORE-SW01, HUAWEI-ACCESS-SW02 |
| `nokia-core-gw01.cfg`, `nokia-dist-gw02.cfg` | Nokia SR OS | NOKIA-CORE-GW01, NOKIA-DIST-GW02 |

See `samples/sample-prompts.txt` for a full list of tested intents per vendor.

## Architecture

NetIntent is a local-first desktop application. All config parsing, secret redaction, and topology inference happen on your machine. The only external communication is the streaming API call to your chosen LLM provider, which receives only redacted config excerpts.

```
┌─────────────────────────────────────────────────────────┐
│                    NetIntent Desktop                     │
│                                                         │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────┐  │
│  │  React UI   │──▶│  Tauri IPC   │──▶│ Rust Backend │  │
│  │  (WebView2) │◀──│  (Commands)  │◀──│  (Native)    │  │
│  └─────────────┘   └──────────────┘   └─────────────┘  │
│         │                                     │         │
│         ▼                                     ▼         │
│  ┌─────────────┐                     ┌─────────────┐    │
│  │  Parser     │                     │  File I/O   │    │
│  │  Redactor   │                     │  SSE Stream  │    │
│  │  Topology   │                     │  (reqwest)   │    │
│  │  Prompts    │                     └──────┬──────┘    │
│  └─────────────┘                            │           │
│                                             ▼           │
│                                  ┌──────────────────┐   │
│                                  │ Claude / Gemini   │   │
│                                  │ OpenAI / Ollama   │   │
│                                  │  (streaming SSE)  │   │
│                                  └──────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Desktop Runtime** | Tauri 2.0 | Native window, IPC bridge, system dialogs, filesystem access |
| **Backend** | Rust | File I/O, streaming HTTPS to LLM APIs via reqwest + rustls-tls |
| **Frontend** | React 18 + TypeScript | UI, state management, multi-vendor config parsing |
| **Persistence** | SQLite (tauri-plugin-sql) | Devices, topology positions, plans, and settings survive restarts |
| **Styling** | Tailwind CSS | Utility-first styling with custom dark theme |
| **Bundler** | Vite + Terser | Production build with identifier mangling, no source maps |
| **Diagram** | SVG (hand-rolled) | Interactive network topology with pan, zoom, drag |

### Data Flow

1. **Upload** — User selects config files via native dialog → Rust reads from disk → returns raw text
2. **Parse** — Frontend detects vendor, splits into sections, extracts hostname/version
3. **Topology** — Topology engine extracts ports, VLANs, and infers inter-device links
4. **Intent** — User describes change → relevant sections extracted, secrets redacted, prompt built
5. **LLM Call** — Rust streams SSE from the provider → emits chunks to frontend via Tauri events
6. **Plan** — Frontend accumulates stream, parses JSON, renders per-device change plans
7. **Projection** — Topology engine applies approved changes to a cloned topology, marks diffs
8. **Export** — Approved changes exported as CLI scripts with rollback via native save dialog

## Security

- **Configs never leave your machine** — parsing, redaction, and topology inference all run locally
- **Only redacted excerpts** are sent to the LLM API — all secrets are stripped first
- **Your API key, your billing** — NetIntent has no servers, no accounts, no telemetry
- **API key stored locally** — saved to SQLite in your app data directory, never sent anywhere except the LLM provider
- **Direct API calls** — your machine talks directly to the provider over TLS
- **No DevTools in production** — the WebView2 inspector is compiled out; right-click and inspect shortcuts are blocked
- **Hardened JS bundle** — identifier mangling, no source maps, console stripped

## Troubleshooting

**"WebView2 not found"**
Download the Evergreen Bootstrapper from [developer.microsoft.com/en-us/microsoft-edge/webview2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)

**API errors**
- Verify your API key is correct in Settings
- Gemini free tier has rate limits (15 RPM) — wait and retry
- Claude and OpenAI require account credit
- Ollama: ensure `ollama serve` is running and the model is pulled (`ollama pull llama3.2`)
- If you see network errors, check that your firewall allows outbound HTTPS to the provider

**Topology not detecting links**
Auto-detection relies on interface descriptions referencing other device hostnames, or matching IP subnets. If your configs don't have these, use Connect mode to manually link ports.

**Vendor detected incorrectly**
Click the vendor badge in the sidebar and select the correct vendor from the dropdown.

## Feedback

When testing, please note any issues with:
- CLI commands that are incorrect or incomplete for a specific vendor/OS version
- Missing warnings for risky changes (STP reconvergence, trunk pruning, etc.)
- Parser failures on production configs (unusual syntax, multi-line banners, etc.)
- Topology detection misses or false positives
- Vendor misdetection

Contact: [hello@netintent.app](mailto:hello@netintent.app)

---

*NetIntent v0.1.0 — Trial · Windows only*
