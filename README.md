# NetIntent — Network Configuration Assistant

AI-powered desktop app for designing networks from scratch or analyzing existing multi-vendor configs — then generating precise CLI change scripts from plain English. All processing happens locally; only redacted excerpts reach the LLM.

> **Trial version** — 7-day trial included. Contact [dlutchman@gmail.com](mailto:dlutchman@gmail.com) to continue.

## Downloads

| OS | File | Notes |
|----|------|-------|
| **Windows** | [`NetIntent_0.3.0_x64-setup.exe`](binaries/windows/NetIntent_0.3.0_x64-setup.exe) | NSIS installer |
| | `NetIntent_0.3.0_x64_en-US.msi` | MSI installer |
| | `netintent.exe` | Portable — no install required |
| **macOS** | [`NetIntent_0.3.0_aarch64.dmg`](binaries/macos/NetIntent_0.3.0_aarch64.dmg) | Apple Silicon disk image |
| **Linux** | [`NetIntent_0.3.0_amd64.deb`](binaries/linux/NetIntent_0.3.0_amd64.deb) | Debian/Ubuntu |
| | `NetIntent_0.3.0_amd64.AppImage` | Portable AppImage |
| | `NetIntent-0.3.0-1.x86_64.rpm` | Fedora/RHEL |

## Quick Start

1. Download the binary for your OS from the table above
2. Gear icon → choose LLM provider → paste API key → Save
3. **Design Network** to generate a full environment from a description, or **Load** existing configs
4. **Make Changes** → describe intent → review plan → export CLI scripts

<img width="1919" height="1031" alt="ni1" src="https://github.com/user-attachments/assets/c82b3a6f-8dbc-4456-af19-266fb2c67cc6" /><img width="1919" height="1033" alt="ni2" src="https://github.com/user-attachments/assets/66f1cea3-1d69-46de-9ead-ffab2375857a" /><img width="1919" height="1031" alt="ni3" src="https://github.com/user-attachments/assets/3ae98631-fafe-4115-b5b5-94ecb20fd731" />

**Windows:** Requires [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) (pre-installed on Windows 10 21H2+)
**macOS:** Apple Silicon (aarch64). Right-click → Open on first launch to bypass Gatekeeper.
**Linux:** Requires WebKitGTK 4.1. On Debian/Ubuntu: `sudo apt install libwebkit2gtk-4.1-0`

## Supported Vendors

Cisco IOS/IOS-XE · Arista EOS · Juniper Junos · Extreme EXOS · Fortinet FortiOS · MikroTik RouterOS · HPE/Aruba · Huawei VRP · Nokia SR OS

## LLM Providers

| Provider | Models |
|----------|--------|
| **Claude** (Anthropic) | Sonnet 4, Opus 4 |
| **Gemini** (Google) | 2.0 Flash, 2.5 Pro |
| **ChatGPT** (OpenAI) | GPT-4o, GPT-4o mini, o1 |
| **Ollama** (local) | Any pulled model |

## How It Works

NetIntent's pipeline processes network configs through six stages — from raw text to validated, exportable CLI scripts. Everything runs locally on your machine; only redacted config excerpts are sent to the LLM.

### 1. Config Parsing & Vendor Detection

When you load a config file, the parser identifies the vendor using pattern-weighted scoring across 10 vendors. Cisco IOS and IOS-XE are distinguished by software version (12–15.x vs 16–17.x). Each vendor has a dedicated section extractor:

- **Cisco/Arista** — block starters (`interface`, `router`, `vlan`, etc.) followed by indented lines until `!` or unindented line
- **Juniper** — `set`-format commands grouped by domain, or hierarchical `{ }` blocks
- **Fortinet** — nested `config ... end` blocks with `edit ... next` sub-sections
- **MikroTik** — path-prefixed sections (`/interface`, `/ip address`)
- **Nokia** — `configure` blocks with deep nesting
- **Extreme/Huawei/HPE** — vendor-specific section headers with indented blocks

For named sections (e.g. `interface GigabitEthernet0/1`), the parser keeps the last occurrence to handle config files where changes are appended rather than merged.

### 2. OpenConfig Normalization

After parsing, each config is normalized into a vendor-neutral structure based on OpenConfig/YANG models:

- **Interfaces** — name, mode (trunk/access/routed/shutdown), VLAN assignments, IP address, MTU, description, channel group
- **VLANs** — ID and name
- **System** — host IPs and router IDs

Eight vendor-specific normalizers extract into a canonical `NormalizedConfig` object. All downstream consumers (topology, validation, prompts) read this structured data instead of re-parsing raw text.

### 3. Secret Redaction

Before anything leaves your machine, 14 regex patterns strip sensitive data:

- Passwords (type 5, 7, enable, username), SNMP communities, TACACS/RADIUS keys
- BGP/OSPF authentication strings, key-chain keys
- Juniper encrypted passwords, Huawei local-user passwords
- Nokia password/secret values, MikroTik `password=` fields, Fortinet private keys

Each redacted value is replaced with `[REDACTED]` and tracked (line number, type, device ID) for multi-device attribution. The original values never leave the machine.

### 4. LLM Prompt Construction & Streaming

The prompt builder assembles context for the LLM with hard constraints:

- **Port usage** — every device's ports are classified as AVAILABLE or CONNECTED; the LLM must only use AVAILABLE ports
- **Relevant sections** — intent keywords ("vlan", "ospf", "trunk") filter which config sections are included, keeping prompts focused
- **Multi-device coordination** — each device block includes connectivity hints (`[connected to: SW1, SW2]`) and cross-device consistency reminders for VLANs, trunks, routing, and IP addressing
- **JSON-only response** — the system prompt enforces structured JSON output with changes, rollback commands, affected sections, warnings, and suggestions

Responses stream token-by-token via Tauri's event system (`llm:chunk` events from Rust → React state), rendering in real-time as the LLM generates.

### 5. Validation Engine

Generated changes pass through multi-layered validation before you can apply them:

**Per-change checks:**
- Interface names verified against the actual config — catches invented ports
- Access VLANs and trunk allowed VLANs must be defined (either in config or earlier in the same plan)
- SVIs without a corresponding VLAN trigger a warning
- ACL entries outside an access-list context are flagged
- Commands after `end` are caught (Cisco/Arista)

**OpenConfig value constraints (per vendor):**
- VLAN ID range, MTU range, IPv4 prefix length, BGP AS number, OSPF cost — all validated against vendor-specific limits derived from YANG models

**Cross-device checks (for generated configs):**
- Duplicate hostnames and IPs across devices
- Orphan next-hops and default gateways pointing to non-existent addresses
- Router-ID uniqueness, MTU mismatches on linked ports

### 6. Config Apply & Export

The config-apply engine supports two modes:

- **Replace** — the LLM provides a complete section; the entire block is swapped in
- **Merge** — the LLM provides CLI commands; each command is matched to existing config lines by a command-key identity system (e.g. `ip address`, `switchport access vlan`) and merged in place

Before committing, a side-by-side diff preview shows the current config vs. the proposed state. Exported CLI scripts include rollback commands for every change.

## Features

### AI Network Design

Describe a network in plain English ("3-tier campus with redundant core, OSPF backbone, VLANs for voice/data/management") and NetIntent generates complete device configs for every device. The design runs in two phases: first an architecture spec, then full configs with matching interface descriptions for automatic topology linking.

### Interactive Topology

The topology view auto-generates a network diagram from loaded configs using two detection strategies:

1. **Description matching** — if two ports reference each other's hostname in their descriptions, a link is created
2. **Subnet inference** — ports on the same IP subnet are linked (lower confidence)

Devices are auto-classified (router, switch, firewall) and arranged in a tiered hierarchy: routers/firewalls at the top, distribution switches in the middle, access switches at the bottom. Drag to reposition, scroll to zoom, and use Connect mode to add manual links. All positions and manual links persist in SQLite.

### Projected Before/After Topology

After generating a change plan, toggle to the projected view to see the network state after applying changes. Links and ports are color-coded: green for added, amber for modified, red for removed. The projection clones the current topology, applies your approved changes, re-runs link detection, and diffs the result.

### Diagnostics

Three AI-driven analysis modes that work on your loaded configs:

- **Diagnose** — describe a symptom ("users on VLAN 10 can't reach the internet") and get root-cause analysis with specific fix commands
- **Optimize** — choose a goal (redundancy, performance, security, simplification, best-practices, scalability) and get targeted recommendations with implementation commands
- **Audit** — full environment health check producing severity-ranked findings and an overall health score

### Multi-device Coordination

When making changes across multiple devices, the LLM receives the full environment context — which devices are connected, what VLANs exist where, how routing is configured — and generates coordinated changes. For example, adding a new VLAN produces trunk changes on distribution switches, access port changes on access switches, and SVI/routing updates on the L3 device, all in one plan.



## Sample Configs

Ten configs in `samples/` covering all supported vendors in a coherent "ACME Corp" multi-vendor enterprise network with cross-device references for topology auto-detection.

## Changelog

### v0.3.0

**OpenConfig normalization layer**
- Vendor-neutral structured extraction runs during parsing — interfaces, VLANs, and system data (host IPs, router IDs) extracted once into a `NormalizedConfig` object
- 8 vendor normalizers consolidate extraction logic previously scattered across topology and validation modules
- ~485 lines of redundant legacy extraction code removed from topology.ts and validate.ts
- 1136 tests passing (43 new normalization tests)

**Structural validation**
- `ACL_ENTRY_MISPLACED` — catches `permit`/`deny` lines placed outside an access-list section context
- `COMMANDS_AFTER_END` — catches commands appended after `end` (Cisco/Arista only; Fortinet's block `end` excluded)

**OpenConfig value-level validation (v0.2.1)**
- VLAN ID range, MTU range, IPv4 prefix length, BGP AS number, and OSPF cost validated per vendor using OpenConfig YANG-derived constraints
- 7 new validation codes: `VLAN_OUT_OF_RANGE`, `MTU_OUT_OF_RANGE`, `PREFIX_LENGTH_INVALID`, `BGP_AS_INVALID`, `OSPF_COST_OUT_OF_RANGE`, `ROUTER_ID_DUPLICATE`, `MTU_MISMATCH`

### v0.2.0

- Multi-vendor config-apply engine (Fortinet, Juniper, Nokia, Aruba, Huawei, Cisco)
- Improved LLM prompt accuracy (port targeting, interface range prohibition)
- Config preview before commit (current/after side-by-side diff)
- Cleaner topology view (smart port filtering, hidden port badges)
- 901 tests across 14 test files

### v0.1.0

- Initial beta: upload → parse → redact → prompt → LLM → plan → export
- 9 vendor parsers, interactive topology, secret redaction, SQLite persistence
- Streaming LLM responses, config validation, multi-device changes

## Troubleshooting

**WebView2 not found** — download from [developer.microsoft.com](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)

**API errors** — verify API key; Gemini free tier has rate limits (15 RPM); Ollama needs `ollama serve` running

**Topology not detecting links** — auto-detection needs interface descriptions referencing hostnames or matching subnets; use Connect mode to link manually

## Security

Configs never leave your machine. Only redacted excerpts reach the LLM. Your API key is stored locally in SQLite. No servers, no accounts, no telemetry.

---

*NetIntent v0.3.0 — Trial · Windows · macOS · Linux*

Contact: [dlutchman@gmail.com](mailto:dlutchman@gmail.com)
