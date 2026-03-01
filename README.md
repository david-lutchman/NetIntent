# NetIntent — Network Config Assistant

AI-powered tool for generating precise Cisco IOS/IOS-XE configuration changes from plain English.

## Quick Start

1. Double-click **NetIntent.exe**
2. Click the **gear icon** (top right) → choose Claude or Gemini → paste your API key → Save
3. Click **Load** to upload one or more device configs (.cfg, .conf, .txt)
4. Check the devices you want to target in the sidebar
5. Click **Make Changes** → describe what you want in plain English → **Analyze**
6. Review the change plan → approve/reject individual changes → **Export Script**

## Getting an API Key

You need your own API key from one of these providers:

| Provider | Get a Key | Cost |
|----------|-----------|------|
| **Claude** (Anthropic) | [console.anthropic.com](https://console.anthropic.com) | $5 free credit on new accounts |
| **Gemini** (Google) | [aistudio.google.com](https://aistudio.google.com/app/apikey) | Free tier available (rate limited) |

## What It Does

- **Parses** Cisco IOS/IOS-XE running configs into browsable sections
- **Detects** vendor, version, and hostname automatically
- **Redacts** all secrets (passwords, SNMP communities, keys) before sending anything to the AI
- **Generates** precise CLI commands based on your plain-English intent
- **Shows** impact ratings (low/medium/high), warnings, and before/after diffs
- **Exports** ready-to-paste config scripts with rollback commands
- **Multi-device** — load your whole environment, target multiple switches, get coordinated changes

## Example Intents

**Single device:**
- "Add VLAN 200 for guest wireless and trunk it to Gi0/1 through Gi0/4"
- "Create an extended ACL to block SSH from 10.0.0.0/8 except 10.1.1.0/24"
- "Shut down all unused access ports and assign them to quarantine VLAN 999"
- "Configure OSPF area 0 on all Layer 3 interfaces"

**Multi-device:**
- "Add VLAN 200 across all switches and ensure all trunks allow it"
- "Standardize NTP servers to 10.0.0.10 and 10.0.0.11 on every device"
- "Set up OSPF authentication on uplink interfaces between CORE-SW01 and DIST-SW01"

## Sample Configs

Two test configs are included in the `samples` folder:

| File | Device | Role | Key Features |
|------|--------|------|-------------|
| `core-sw01.cfg` | CORE-SW01 | Core switch | VLANs 10/20/30/99, OSPF, trunks, ACL, 8 interfaces |
| `dist-sw01.cfg` | DIST-SW01 | Distribution switch | Same VLANs, uplinks to core, 10 interfaces |

Load both to test multi-device changes.

## Security

- **Configs never leave your machine** — parsing and redaction happen locally
- **Only redacted excerpts** are sent to the LLM API (secrets stripped)
- **Your API key, your billing** — NetIntent has no servers and no accounts
- **API keys are stored in memory only** — not written to disk (cleared when you close the app)

## System Requirements

- Windows 10 or 11 (64-bit)
- WebView2 runtime (included in Windows 10/11 by default)
- Internet connection (for API calls to Claude or Gemini)

## Troubleshooting

**"Windows protected your PC" (SmartScreen)**
This appears because the app is not code-signed yet. Click "More info" → "Run anyway".

**"WebView2 not found"**
Download from [developer.microsoft.com/en-us/microsoft-edge/webview2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)

**API errors**
- Check your API key is correct in Settings
- Gemini free tier has rate limits — wait 30 seconds and retry
- Claude requires credit on your Anthropic account

## Feedback

Please note any issues with:
- Commands that don't look right for a specific platform/version
- Missing warnings for risky changes
- Parser failures on your production configs
- UI/UX friction points

---

*NetIntent v0.1.0 — Phase 1 Beta*
