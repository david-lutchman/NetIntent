# NetIntent — Network Configuration Assistant

AI-powered desktop app for designing networks from scratch or analyzing existing multi-vendor configs — then generating precise CLI change scripts from plain English. All processing happens locally; only redacted excerpts reach the LLM.

> **Trial version** — 7-day trial included. Contact [dlutchman@gmail.com](mailto:dlutchman@gmail.com) to continue.

## Quick Start

1. Download `target/release/netintent.exe` — no installer required
2. Gear icon → choose LLM provider → paste API key → Save
3. **Design Network** to generate a full environment from a description, or **Load** existing configs
4. **Make Changes** → describe intent → review plan → export CLI scripts

<img width="1919" height="1031" alt="ni1" src="https://github.com/user-attachments/assets/c82b3a6f-8dbc-4456-af19-266fb2c67cc6" /><img width="1919" height="1033" alt="ni2" src="https://github.com/user-attachments/assets/66f1cea3-1d69-46de-9ead-ffab2375857a" /><img width="1919" height="1031" alt="ni3" src="https://github.com/user-attachments/assets/3ae98631-fafe-4115-b5b5-94ecb20fd731" />

**Requires:** Windows 10/11 with [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) (pre-installed on Windows 10 21H2+)

## Supported Vendors

Cisco IOS/IOS-XE · Arista EOS · Juniper Junos · Extreme EXOS · Fortinet FortiOS · MikroTik RouterOS · HPE/Aruba · Huawei VRP · Nokia SR OS

## LLM Providers

| Provider | Models |
|----------|--------|
| **Claude** (Anthropic) | Sonnet 4, Opus 4 |
| **Gemini** (Google) | 2.0 Flash, 2.5 Pro |
| **ChatGPT** (OpenAI) | GPT-4o, GPT-4o mini, o1 |
| **Ollama** (local) | Any pulled model |

## Features

- **AI Network Design** — describe a network in plain English, get complete device configs for every device
- **Interactive Topology** — auto-generated from configs via description matching and subnet detection; drag, zoom, pan, manual link creation
- **Projected Before/After** — toggle current vs. post-change topology with color-coded diffs (added/modified/removed)
- **OpenConfig Normalization** — vendor-neutral structured extraction (interfaces, VLANs, system data) runs once during parsing; all consumers read structured data instead of re-parsing raw text
- **Change Validation** — catches invented interfaces, undefined VLANs, duplicate IPs, orphan next-hops, router-ID conflicts, MTU mismatches, misplaced ACL entries, and commands after `end`
- **OpenConfig Value Constraints** — VLAN range, MTU range, prefix length, BGP AS, and OSPF cost validated per vendor
- **Secret Redaction** — passwords, SNMP communities, TACACS/RADIUS keys, BGP/OSPF auth stripped before LLM call
- **Streaming Responses** — token-by-token rendering as the LLM generates
- **Multi-device Coordination** — cross-device consistency for VLANs, trunks, routing, and IP addressing
- **Config Apply Engine** — vendor-native in-place merge for Cisco, Juniper, Fortinet, Nokia, Aruba, Huawei
- **SQLite Persistence** — devices, topology positions, plans, and settings survive restarts
- **Export** — per-device or environment-wide CLI scripts with rollback commands

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

*NetIntent v0.3.0 — Trial · Windows only*

Contact: [dlutchman@gmail.com](mailto:dlutchman@gmail.com)
