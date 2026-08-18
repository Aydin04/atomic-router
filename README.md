<div align="center">

# ⚡ AtomicRouter

**Ultra-Lightweight Universal AI Gateway & Proxy (Streamlined Pure Fork of OmniRoute)**

*One unified OpenAI/Claude endpoint, 330+ LLM providers, Multi-Account OAuth, Smart Combos, Proxy Pools, and Native Stream Compression.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Node: 20+](https://img.shields.io/badge/Node.js-20%2B-green.svg)](https://nodejs.org)
[![RAM: 512MB+](https://img.shields.io/badge/RAM-512MB%20Optimized-cyan.svg)](#)

</div>

---

## 🚀 1-Line Automated Installer

Deploy **AtomicRouter** instantly on any Ubuntu / Debian / CentOS / Alpine VPS (including low-spec 512MB – 1GB VPS):

```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | bash
```

*The installer automatically provisions temporary swap if RAM < 1.5 GB, installs Node.js 22 LTS, builds the memory-capped standalone gateway, and registers a background systemd service.*

---

## 🌟 Key Features (Pure Gateway Engine)

### 1. 🔀 Smart Combos & Auto-Fallback Routing
- Combine multiple models/providers into a single virtual endpoint.
- Strategies: **Priority Fallback**, **Weighted**, **Round-Robin**, **Least-Used**, **Headroom**, **Context-Optimized**, and **Fusion**.
- Automatic circuit breaker & retry with exponential backoff on `429` / `503`.

### 2. 🔌 330+ Supported AI Providers Out-of-the-Box
- **Proprietary & Enterprise**: OpenAI, Anthropic, Google Gemini / Antigravity Cloud Assist, xAI Grok, Azure, AWS Bedrock, Kiro.
- **Aggregators & Routers**: OpenRouter, DeepInfra, Together AI, Groq, Fireworks, Cerebras, Sambanova, Novita, Hyperbolic.
- **100% Free Public Proxies**: DuckDuckGo Web, Puter, Pollinations, LMArena, FreeMiMo.
- **Local Self-Hosted**: Ollama, LM Studio, vLLM, Triton, Llamafile.

### 3. 👥 Multi-Account Connection Pool per Provider
- Login **multiple accounts** for the same provider (e.g., 5 Claude accounts, 3 Google Antigravity accounts, 10 OpenAI accounts).
- Automatic rotation and transparent failover when one account hits rate limit quotas.

### 4. 🌐 Proxy Pools & Upstream IP Rotation
- Assign specific HTTP / SOCKS5 proxies per provider or rotate dynamically across proxy pools to prevent geo-blocking and IP bans.

### 5. 🎁 Free Models Explorer
- Real-time catalog of 100% free models across all connected providers with live quota & latency discovery.

### 6. 🗜️ Native Brotli & Gzip Stream Compression
- High-efficiency compression for JSON payloads and SSE streaming responses (reduces bandwidth by up to 70%).

### 7. 🛡️ Ultra-Low Memory & Anti-OOM Build System
- Capped memory build pipeline (`NODE_OPTIONS="--max-old-space-size=450"`).
- Runtime footprint only **~50 MB – 120 MB RAM**, running smoothly on 512MB – 1GB VPS.

---

## 🛠️ Manual Installation & Running

### Using Git & Node.js

```bash
# 1. Clone repository
git clone https://github.com/dianrestu/atomic-router.git
cd atomic-router

# 2. Copy environment file
cp .env.example .env

# 3. Install dependencies
NODE_OPTIONS="--max-old-space-size=450" npm install

# 4. Build standalone gateway
npm run build

# 5. Start gateway server
npm start
```

Default dashboard: `http://localhost:20128/`

---

## 🐳 Docker Deployment

```bash
docker compose up -d --build
```

---

## 🔌 Client Integrations (Cursor, Cline, NextChat, Python)

Point your favorite AI coding tool or client to AtomicRouter:

### Cursor / Cline / Roo Code / OpenWebUI
- **Base URL**: `http://<your-vps-ip>:20128/v1`
- **API Key**: `sk-atomic-gateway-master` (or any custom master key created in the dashboard)

### Python (OpenAI SDK)
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:20128/v1",
    api_key="sk-atomic-gateway-master"
)

response = client.chat.completions.create(
    model="antigravity/gemini-2.5-pro", # or claude-3-7-sonnet, gpt-4o, combo/fast
    messages=[{"role": "user", "content": "Hello world!"}]
)

print(response.choices[0].message.content)
```

---

## 📜 Acknowledgements & Lineage

AtomicRouter is a streamlined, pure AI gateway fork built upon the foundation of [OmniRoute](https://github.com/diegosouzapw/OmniRoute) with heavy non-gateway subsystems (MCP servers, A2A agents, vector memory) stripped for maximum speed, minimal resource usage, and seamless execution on low-spec VPS servers.

---

## 📄 License

MIT License © 2026 [Dian Restu](https://github.com/dianrestu).
