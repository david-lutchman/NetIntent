# NetIntent — Network Configuration Assistant

AI-powered desktop application for analyzing Cisco IOS/IOS-XE configurations and generating precise CLI change scripts from plain English. Load your entire environment, visualize the topology, describe what you want, and export ready-to-paste commands.

## Quick Start

### Build from source

```bash
git clone https://github.com/david-lutchman/NetIntent.git
cd NetIntent
npm install
cargo tauri build   # → src-tauri/target/release/netintent.exe
```

**Prerequisites:** [Node.js 18+](https://nodejs.org), [Rust](https://rustup.rs), [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)

### Using the app

1. Launch the app
2. Click the **gear icon** (top right) → choose Claude or Gemini → paste your API key → Save
3. Click **Load** to upload one or more device configs (.cfg, .conf, .txt)
4. Check the devices you want to target in the sidebar
5. Click **Make Changes** → describe what you want in plain English → **Analyze**
6. Review the change plan → approve/reject individual changes
7. Click **View Topology** to see the projected network state after changes
8. **Export** scripts per device or all at once

## Getting an API Key

You need your own API key from one of these providers:

| Provider | Get a Key | Cost |
|----------|-----------|------|
| **Claude** (Anthropic) | [console.anthropic.com](https://console.anthropic.com) | Pay-as-you-go after free trial credit |
| **Gemini** (Google) | [aistudio.google.com](https://aistudio.google.com/app/apikey) | Free tier available (rate limited) |

## Features

### Multi-Device Environment
Load your entire switching and routing environment. Upload multiple configs at once or add devices over time. Every device appears in the sidebar with vendor detection, section counts, and a target checkbox for selecting which devices to include in change analysis.

### Config Parser
Automatically detects Cisco IOS vs IOS-XE, extracts hostname and version, and splits the running config into browsable sections — interfaces, VLANs, routing protocols, ACLs, line configs, crypto, QoS, and global commands. Filter by section type to quickly find what you need.

### Interactive Network Topology
An auto-generated network diagram built from your uploaded configs. The topology engine detects connections two ways: by matching interface descriptions that reference other device hostnames (e.g. "UPLINK-TO-DIST-SW01"), and by matching IP subnets across devices. The diagram supports:

- **Drag** to reposition devices (positions are preserved)
- **Scroll** to zoom, **drag background** to pan, **Fit** button to auto-frame
- **Port dots** along each device, color-coded by mode (blue = trunk, green = access, amber = routed, gray = shutdown)
- **Hover** any port for name, mode, VLAN, and allowed VLAN details
- **Connect mode** — manually link two ports across devices by clicking them
- **Delete links** — select a link and remove it
- **Port detail panel** — click the ℹ button on any device to see all interfaces, SVIs, IP addresses, and what each port connects to
- **Double-click** any device to jump to its config view

### Projected Topology (Before/After)
After generating a change plan, click **View Topology** or use the sidebar Topology tab. A **Current / After Changes** toggle lets you compare the network as it is now versus what it will look like after approved changes are applied. Visual diff encoding highlights what changed:

- Green ring + **NEW** badge on added ports, VLANs, and links
- Amber ring + **MOD** badge on modified ports (mode changes, VLAN reassignment, trunk updates)
- Red dashed + **DEL** badge on removed or shutdown elements
- Devices with changes get a dashed teal border
- The port detail panel shows VLAN additions and removals inline

The projection updates live — toggle changes on/off in the plan view and the topology reflects it immediately.

### Secret Redaction
All passwords, enable secrets, SNMP communities, TACACS/RADIUS keys, BGP neighbor passwords, OSPF/EIGRP authentication keys, and crypto pre-shared keys are automatically stripped before anything is sent to the LLM. A redaction panel shows exactly what was found, with per-item reveal toggles.

### AI-Powered Change Generation
Describe your intent in plain English. The system extracts only the relevant config sections, redacts secrets, and sends them to your chosen LLM along with a structured system prompt that enforces valid CLI syntax, proper command hierarchy, impact assessment, and rollback generation. Supports both single-device and coordinated multi-device changes.

### Change Plan Review
Every generated change is individually approvable with full context: action type (add/modify/remove), affected section, reasoning, impact rating (low/medium/high), and the exact CLI commands. Copy individual command blocks to clipboard, view before/after diffs per section, and export per-device or environment-wide scripts with rollback commands included.

## Example Intents

**Single device:**
- "Add VLAN 200 for guest wireless and trunk it to Gi0/1 through Gi0/4"
- "Create an extended ACL to block SSH from 10.0.0.0/8 except 10.1.1.0/24"
- "Shut down all unused access ports and assign them to quarantine VLAN 999"
- "Configure OSPF area 0 on all Layer 3 interfaces"
- "Add an IP helper-address for DHCP relay on VLAN 100 pointing to 10.0.0.50"

**Multi-device:**
- "Add VLAN 200 across all switches and ensure all trunks allow it"
- "Set up an OSPF adjacency between CORE-SW01 and DIST-SW01 on their uplink interfaces"
- "Standardize NTP servers to 10.0.0.10 and 10.0.0.11 on every device"
- "Create a consistent management ACL on all VTY lines across the environment"
- "Change the native VLAN on all trunk ports from 1 to 999"

## Architecture

### Overview

NetIntent is a local-first desktop application. All config parsing, secret redaction, and topology inference happen on your machine. The only external communication is the API call to your chosen LLM provider, which receives only redacted config excerpts.

```
┌─────────────────────────────────────────────────────────┐
│                    NetIntent Desktop                     │
│                                                         │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────┐  │
│  │  React UI   │──▶│  Tauri IPC   │──▶│ Rust Backend │  │
│  │  (WebView)  │◀──│  (Commands)  │◀──│  (Native)    │  │
│  └─────────────┘   └──────────────┘   └─────────────┘  │
│         │                                     │         │
│         ▼                                     ▼         │
│  ┌─────────────┐                     ┌─────────────┐    │
│  │  Parser     │                     │  File I/O   │    │
│  │  Redactor   │                     │  HTTP Client │    │
│  │  Topology   │                     │  (reqwest)   │    │
│  │  Prompts    │                     └──────┬──────┘    │
│  └─────────────┘                            │           │
│                                             ▼           │
│                                    ┌─────────────────┐  │
│                                    │ Claude / Gemini  │  │
│                                    │   API (remote)   │  │
│                                    └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Desktop Runtime** | Tauri 2.0 | Native window, IPC bridge, system dialogs, filesystem access |
| **Backend** | Rust | File I/O, HTTPS requests to LLM APIs via reqwest + rustls-tls |
| **Frontend** | React 18 + TypeScript | UI components, state management, config parsing |
| **Persistence** | SQLite (tauri-plugin-sql) | Devices, topology positions, plans, and settings survive restarts |
| **Styling** | Tailwind CSS | Utility-first styling with custom dark theme |
| **Bundler** | Vite | Development server with hot module replacement |
| **Diagram** | SVG (hand-rolled) | Interactive network topology with pan, zoom, drag |

### Frontend Modules

| Module | Responsibility |
|--------|---------------|
| `App.tsx` | Root layout, view routing, device state management |
| `lib/parser.ts` | Vendor detection (IOS vs IOS-XE), config sectioning, intent-based section filtering |
| `lib/redact.ts` | 15 regex rules for stripping passwords, keys, communities before LLM submission |
| `lib/db.ts` | SQLite persistence via tauri-plugin-sql (devices, topology, plans, settings) |
| `lib/prompts.ts` | System and user prompt construction for single and multi-device analysis |
| `lib/topology.ts` | Port extraction, connection detection, topology projection after changes |
| `lib/types.ts` | TypeScript interfaces for all data structures |
| `components/NetworkDiagram.tsx` | Interactive SVG canvas with drag, zoom, connect mode, diff visualization |

### Rust Backend Commands

| IPC Command | Function |
|-------------|----------|
| `read_config_file` | Reads a file from disk, returns content + metadata |
| `save_file` | Writes exported change scripts to disk |
| `call_claude` | HTTPS POST to Anthropic Messages API |
| `call_gemini` | HTTPS POST to Google Gemini generateContent API |

### Data Flow

1. **Upload** — User selects config files via native file dialog → Rust reads from disk → returns raw text to frontend
2. **Parse** — Frontend parser detects vendor, splits into sections, extracts hostname/version
3. **Topology** — Frontend topology engine extracts ports, VLANs, and infers inter-device links
4. **Intent** — User describes desired change → frontend filters relevant sections, redacts secrets, builds prompt
5. **LLM Call** — Rust backend sends HTTPS request to Claude or Gemini with redacted excerpts → returns structured JSON
6. **Plan** — Frontend parses response into per-device change plans with approval controls
7. **Projection** — Topology engine applies approved CLI commands to a cloned topology, re-detects links, marks diffs
8. **Export** — Approved changes exported as CLI scripts with rollback via native save dialog

### Why Tauri + Rust

Tauri was chosen over Electron for three reasons: binary size (~8 MB vs ~150 MB), memory footprint (~30 MB vs ~300 MB), and the fact that config files never need to leave the local filesystem — Rust handles file I/O and HTTPS natively without bundling a full Node.js runtime. The WebView2 backend uses the system-installed Edge runtime, keeping the distribution lean.

## Sample Configs

Two test configs are included in the `samples` folder:

| File | Device | Role | Key Features |
|------|--------|------|-------------|
| `core-sw01.cfg` | CORE-SW01 | Core switch | VLANs 10/20/30/99, OSPF, trunks, ACL, 8 interfaces |
| `dist-sw01.cfg` | DIST-SW01 | Distribution switch | Same VLANs, uplinks to core, OSPF, 10 interfaces |

Load both to test multi-device changes and topology auto-detection. The uplink interfaces reference each other by hostname, so the topology engine will detect the link automatically.

## Security

- **Configs never leave your machine** — parsing, redaction, and topology inference all run locally
- **Only redacted excerpts** are sent to the LLM API — all secrets are stripped first
- **Your API key, your billing** — NetIntent has no servers, no accounts, no telemetry
- **API key stored locally** — saved to SQLite in your app data directory, never sent anywhere except the LLM provider
- **Direct API calls** — your machine talks directly to api.anthropic.com or generativelanguage.googleapis.com over TLS

## System Requirements

- Windows 10 or 11 (64-bit)
- WebView2 runtime (included in Windows 10 21H2+ and all Windows 11)
- Internet connection (for API calls to Claude or Gemini only)

## Troubleshooting

**"WebView2 not found"**
Download the Evergreen Bootstrapper from [developer.microsoft.com/en-us/microsoft-edge/webview2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)

**API errors**
- Verify your API key is correct in Settings
- Gemini free tier has rate limits (15 RPM) — wait 30 seconds and retry
- Claude requires credit on your Anthropic account
- If you see CORS or network errors, check that your firewall allows outbound HTTPS

**Topology not detecting links**
Auto-detection relies on interface descriptions referencing other hostnames, or matching IP subnets. If your configs don't have these, use Connect mode to manually link ports.

## Feedback

When testing, please note any issues with:
- CLI commands that are incorrect or incomplete for a specific IOS version
- Missing warnings for risky changes (STP reconvergence, trunk pruning, etc.)
- Parser failures on production configs (unusual syntax, multi-line banners, etc.)
- Topology detection misses or false positives
- UI/UX friction points

---

*NetIntent v0.1.0 — Beta · Build from source · Windows only*
