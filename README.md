<div align="center">

# ⚡ AtomicRouter

**Ultra-Lightweight Universal AI Gateway & Smart Proxy**
*(Streamlined Pure Gateway Fork of OmniRoute — 330+ Providers, Combos, Multi-Account Pool & Zero Bloat)*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Node: 22 LTS](https://img.shields.io/badge/Node.js-22%20LTS-green.svg)](https://nodejs.org)
[![RAM: 512MB+](https://img.shields.io/badge/RAM-512MB%20Optimized-cyan.svg)](#)
[![Speed: Instant Install](https://img.shields.io/badge/Install-30%20Seconds-orange.svg)](#)

</div>

---

## 🚀 1-Line Quick Install (Any Linux VPS)

Deploy **AtomicRouter** instantly on any Ubuntu / Debian / CentOS / Rocky Linux VPS (including low-spec 512MB – 1GB RAM machines):

```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | sudo bash
```

> ⚡ **How it works**: The installer downloads a pre-compiled standalone release package, auto-provisions Node.js 22 LTS, generates unique local cryptographic keys, and configures a resilient systemd background service in **under 30 seconds**.

---

## ⚡ Convenient Management CLI (`atomic-router`)

Once installed, manage your gateway easily with the global `atomic-router` command:

```bash
# Update to latest release (Takes ~5 seconds, keeps 100% database & logins intact)
sudo atomic-router update

# Check live service status & health
atomic-router status

# View live real-time request logs
atomic-router logs

# Restart or stop gateway
atomic-router restart
atomic-router stop
atomic-router start

# Check current version
atomic-router version
```

---

## 🌟 Key Features (Pure Gateway Engine)

### 1. 🔀 Smart Combos & Auto-Fallback Routing
- Combine multiple models or providers into a single virtual OpenAI-compatible model endpoint.
- **19 Routing Strategies**: Priority Fallback, Weighted, Round-Robin, Least-Used, Headroom, Context-Optimized, Fusion, and Auto.
- Automatic circuit breaker with exponential backoff on `429 (Rate Limit)` and `503 (Overloaded)`.

### 2. 🔌 330+ Supported AI Providers Out-of-the-Box
- **Proprietary & Enterprise**: OpenAI, Anthropic, Google Gemini / Antigravity Cloud Assist, xAI Grok, Azure, AWS Bedrock, Kiro, Codex.
- **Aggregators & Routers**: OpenRouter, DeepInfra, Together AI, Groq, Fireworks, Cerebras, Sambanova, Novita, Hyperbolic.
- **100% Free Public Proxies**: DuckDuckGo Web, Puter, Pollinations, LMArena, FreeMiMo.
- **Local Self-Hosted**: Ollama, LM Studio, vLLM, Triton, Llamafile.

### 3. 👥 Multi-Account Connection Pool per Provider
- Connect **multiple accounts** for any provider (e.g. 5 Claude accounts, 3 Google Antigravity accounts, 10 OpenAI keys).
- Transparent auto-rotation and instant failover when one account exhausts its rate limit or quota.

### 4. 🌐 Upstream Proxy Pools & IP Rotation
- Assign dedicated HTTP / SOCKS5 proxies per provider or rotate dynamically across proxy pools to prevent geo-blocking and IP bans.

### 5. 🗄️ Full Database Backup, Export & Import
- Seamlessly backup and restore all accounts, OAuth tokens, combos, and proxy configs between VPS servers.
- Supports `.tar.gz` database archive, raw SQLite snapshots, and JSON settings export/import.

### 6. 🗜️ Native Brotli & Gzip Stream Compression
- High-efficiency compression for SSE streaming responses and JSON payloads (saves up to 70% bandwidth).

### 7. 🛡️ Ultra-Low RAM Footprint (~40 MB – 80 MB)
- Stripped of heavy non-gateway bloatware (Electron, vector databases, browser automation).
- Runs cold and fast on any 512MB – 1GB VPS with 0% CPU lockup.

---

## 🔌 Client Integrations (Cursor, Cline, Python, OpenAI SDK)

Point your tools to your AtomicRouter instance:

### Cursor / Cline / Roo Code / OpenWebUI
- **Base URL**: `http://<your-vps-ip>:20128/v1`
- **API Key**: `Bearer <your-api-key>` (Configurable in Dashboard)

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<your-vps-ip>:20128/v1",
    api_key="your-atomic-router-key",
)

response = client.chat.completions.create(
    model="claude-3-7-sonnet-20250219",  # or any combo name like "smart-combo"
    messages=[{"role": "user", "content": "Hello!"}],
)

print(response.choices[0].message.content)
```

---

## 📄 License & Upstream

- AtomicRouter is a pure streamlined gateway fork of [OmniRoute](https://github.com/diegosouzapw/OmniRoute) by Diego Souza.
- Licensed under the [MIT License](LICENSE).
