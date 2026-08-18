<div align="center">

# ⚡ AtomicRouter

**Ultra-Lightweight Universal AI Gateway & Smart Proxy**
*(Streamlined Pure Gateway Fork — 330+ Providers, Combos, Multi-Account Pool & Native Stream Compression)*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Node: 22 LTS](https://img.shields.io/badge/Node.js-22%20LTS-green.svg)](https://nodejs.org)
[![Platform: Linux | macOS | Windows | Pi | Termux](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Pi%20%7C%20Termux-blueviolet.svg)](#)
[![RAM: 512MB+](https://img.shields.io/badge/RAM-512MB%20Optimized-cyan.svg)](#)

</div>

---

## 🚀 1-Line Quick Installers (Multi-Platform)

### 🐧 Linux / VPS / Ubuntu / Debian / CentOS / Arch
```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | sudo bash
```

### 🪟 Windows (1-Line PowerShell)
Buka **PowerShell** dan jalankan:
```powershell
irm https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.ps1 | iex
```
*(Atau unduh file zip `atomic-router-windows-x64.zip` dari [Releases](https://github.com/dianrestu/atomic-router/releases/latest) lalu double-click `start.bat`)*

### 🍎 macOS (Apple Silicon & Intel)
```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | bash
```

### 🍓 Raspberry Pi / Orange Pi / Linux ARM64
```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | sudo bash
```

### 📱 Android Termux
Buka aplikasi **Termux** dan jalankan:
```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | bash
```

---

## ⚡ Convenient Management CLI (`atomic-router`)

Pada Linux VPS atau Termux, kelola gateway Anda dengan mudah melalui perintah global `atomic-router`:

```bash
# Update ke rilis terbaru (Mempertahankan 100% database, akun & login)
sudo atomic-router update

# Cek status kesehatan gateway
atomic-router status

# Lihat log request secara real-time
atomic-router logs

# Restart / Start / Stop service
atomic-router restart
atomic-router stop
atomic-router start
```

---

## 🌟 Key Features (Pure Gateway Engine)

### 1. 🔀 Smart Combos & Auto-Fallback Routing
- Gabungkan banyak model/provider ke dalam 1 virtual endpoint OpenAI-compatible.
- **19 Strategi Routing**: Priority Fallback, Weighted, Round-Robin, Least-Used, Headroom, Context-Optimized, Fusion, dan Auto.
- Automatic circuit breaker dengan exponential backoff pada `429 (Rate Limit)` dan `503 (Overloaded)`.

### 2. 🔌 330+ Supported AI Providers Out-of-the-Box
- **Proprietary & Enterprise**: OpenAI, Anthropic, Google Gemini / Antigravity Cloud Assist, xAI Grok, Azure, AWS Bedrock, Kiro, Codex.
- **Aggregators & Routers**: OpenRouter, DeepInfra, Together AI, Groq, Fireworks, Cerebras, Sambanova, Novita, Hyperbolic.
- **100% Free Public Proxies**: DuckDuckGo Web, Puter, Pollinations, LMArena, FreeMiMo.
- **Local Self-Hosted**: Ollama, LM Studio, vLLM, Triton, Llamafile.

### 3. 👥 Multi-Account Connection Pool per Provider
- Hubungkan **banyak akun sekaligus** untuk provider yang sama (contoh: 5 akun Claude, 3 akun Google Antigravity, 10 API keys OpenAI).
- Rotasi otomatis dan failover instan saat satu akun kehabisan kuota atau terkena rate limit.

### 4. 🌐 Upstream Proxy Pools & IP Rotation
- Konfigurasi HTTP / SOCKS5 proxy khusus per provider atau rotasi dinamis proxy pool untuk mencegah geo-blocking dan IP ban.

### 5. 🗄️ Full Database Backup, Export & Import
- Backup dan restore database SQLite, seluruh akun, token OAuth, dan combos antar server VPS dengan mudah.
- Mendukung format `.tar.gz`, raw `.sqlite`, dan export/import JSON.

### 6. 🗜️ Native Brotli & Gzip Stream Compression
- Kompresi efisiensi tinggi untuk SSE streaming responses dan JSON payloads (menghemat bandwidth hingga 70%).

### 7. 🛡️ Ultra-Low RAM Footprint (~40 MB – 80 MB)
- Bebas dari bloatware non-gateway yang berat.
- Berjalan ringan dan dingin pada VPS 512MB – 1GB dengan 0% CPU lockup.

---

## 🔌 Client Integrations (Cursor, Cline, Python, OpenAI SDK)

Arahkan tools coding atau AI client favorit Anda ke instance AtomicRouter:

### Cursor / Cline / Roo Code / OpenWebUI
- **Base URL**: `http://<ip-vps-anda>:20128/v1`
- **API Key**: `Bearer <api-key-anda>` (Bisa diatur di Dashboard)

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<ip-vps-anda>:20128/v1",
    api_key="your-atomic-router-key",
)

response = client.chat.completions.create(
    model="claude-3-7-sonnet-20250219",  # atau nama combo seperti "smart-combo"
    messages=[{"role": "user", "content": "Hello!"}],
)

print(response.choices[0].message.content)
```

---

## 📄 License & Credits

- AtomicRouter is a pure streamlined gateway fork based on [OmniRoute](https://github.com/diegosouzapw/OmniRoute) by Diego Souza.
- Licensed under the [MIT License](LICENSE).
