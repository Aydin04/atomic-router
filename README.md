<div align="center">

# ⚡ AtomicRouter

### Universal AI Gateway & High-Performance Smart Routing Engine

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node: 22 LTS](https://img.shields.io/badge/Node.js-22%20LTS-green.svg)](https://nodejs.org)
[![Platform: Linux | macOS | Windows | ARM64](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20ARM64-blueviolet.svg)](#installation)
[![RAM: ~50MB Footprint](https://img.shields.io/badge/Memory-~50MB%20Optimized-cyan.svg)](#performance--footprint)
[![Release: v3.8.50](https://img.shields.io/badge/Release-v3.8.50-brightgreen.svg)](https://github.com/dianrestu/atomic-router/releases)

<p align="center">
  <b>A unified, resilient, and blazing-fast AI gateway that bridges 330+ LLM providers into standard OpenAI-compatible endpoints with intelligent multi-account failover, dynamic load balancing, proxy pooling, and real-time stream compression.</b>
</p>

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture & Request Lifecycle](#-architecture--request-lifecycle)
- [Performance & Footprint](#-performance--footprint)
- [Installation](#-installation)
  - [Linux (Ubuntu / Debian / CentOS / Rocky)](#1-linux--vps-systemd-service)
  - [Windows (x64)](#2-windows-standalone)
  - [macOS (Apple Silicon & Intel)](#3-macos-standalone)
  - [Raspberry Pi & Linux ARM64](#4-raspberry-pi--linux-arm64)
  - [Android (Termux)](#5-android-termux)
- [Management CLI (`atomic-router`)](#-management-cli-atomic-router)
- [Smart Combos & Routing Strategies](#-smart-combos--routing-strategies)
- [Client Integration Guides](#-client-integration-guides)
  - [OpenAI Python SDK](#openai-python-sdk)
  - [Cursor / Cline / Roo Code](#cursor--cline--roo-code)
  - [LangChain & LlamaIndex](#langchain--llamaindex)
  - [cURL](#curl)
- [Configuration & Security](#-configuration--security)
- [License](#-license)

---

## 🌐 Overview

**AtomicRouter** provides developer teams and enterprise applications with a single, highly reliable endpoint for all AI workloads. By decoupling upstream provider APIs (OpenAI, Anthropic Claude, Google Gemini, xAI Grok, Azure OpenAI, AWS Bedrock, local LLMs, and 300+ others) from downstream client applications, AtomicRouter ensures continuous uptime, zero provider lock-in, and granular cost control.

```
┌─────────────────────────────────────────────────────────────┐
│                 Client Applications / SDKs                  │
│       (Cursor, Cline, Python SDK, LangChain, OpenWebUI)     │
└──────────────────────────────┬──────────────────────────────┘
                               │ OpenAI-Compatible /v1 API
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   ⚡ AtomicRouter Gateway                    │
│  ┌───────────────────┐ ┌───────────────────┐ ┌────────────┐ │
│  │ Circuit Breakers  │ │ 19 Routing Combo  │ │ Proxy Pool │ │
│  │ & Cooldown Matrix │ │ Policy Engine     │ │ & Rotation │ │
│  └───────────────────┘ └───────────────────┘ └────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │   Multi-Account Connection Pool (Keys & OAuth Tokens)  │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │   Native Streaming Brotli & Gzip Compression Engine    │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────┘
                               │ Upstream Protocol Translation
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 330+ Supported AI Providers                 │
│  OpenAI • Anthropic • Gemini • Grok • Groq • Bedrock • Ollama│
└─────────────────────────────────────────────────────────────┘
```

---

## 🌟 Key Features

### 🔌 330+ AI Providers Unified
- **Tier-1 Commercial**: OpenAI, Anthropic, Google Gemini / Antigravity Cloud Assist, xAI Grok, Azure OpenAI, AWS Bedrock, Mistral AI, Cohere.
- **High-Speed Aggregators**: OpenRouter, DeepInfra, Groq, Fireworks AI, Together AI, Cerebras, Sambanova, Novita, Hyperbolic.
- **Local & Self-Hosted**: Ollama, LM Studio, vLLM, LocalAI, Triton, Llamafile.
- **Universal Translation**: Automatically translates standard OpenAI chat completions, responses, function/tool calling, and streaming SSE tokens to provider-specific formats (e.g., Anthropic Messages API, Gemini Content API).

### 🔀 Smart Combos & 19 Dynamic Routing Strategies
Combine multiple models, accounts, and providers into a unified virtual model:
- **Priority Cascade**: Tries primary models first, immediately falling back to backup models on outage or quota depletion.
- **Weighted Load Balancing**: Distributes requests across targets according to assigned percentage weights.
- **Round-Robin & Least-Used**: Evenly balances high-volume workloads across pooled connections.
- **Auto-Score Routing**: Dynamically scores candidates across 14 runtime factors including latency, historical error rate, context window depth, and cost.
- **Fusion Multi-Model Consensus**: Fans out prompts in parallel to multiple models and employs a synthesis arbiter to construct the final response.

### 👥 Multi-Account Connection Pooling & Instant Failover
- Attach unlimited accounts or API keys to any single provider.
- Granular connection cooldowns: When an account hits a `429 (Rate Limit)` or quota boundary, the gateway automatically rotates to the next available account without dropping client connections.
- Automatic exponential backoff and jittered cooldown resets prevent thundering-herd issues.

### 🌐 Upstream Proxy Pools & IP Rotation
- Configure dedicated HTTP, HTTPS, or SOCKS5 proxies per provider or pool proxies across rotational health-check groups.
- Overcomes geographic restrictions, corporate firewalls, and provider-level IP throttles.

### 🗜️ Native High-Performance Stream Compression
- Integrated Brotli and Gzip stream compression for Server-Sent Events (SSE) and JSON responses.
- Saves up to 70% bandwidth during long context processing and code generation tasks with negligible CPU overhead.

### 🛡️ Enterprise Security & Quota Controls
- Role-based API key management with granular per-key rate limits, budget ceilings, and allowed model policies.
- Cryptographically isolated local storage (AES-256-GCM credential encryption at rest).
- Fully air-gapped deployment capability: All routing and proxying happens locally on your infrastructure with zero external telemetry.

---

## ⚡ Performance & Footprint

AtomicRouter is engineered specifically for low-overhead, high-throughput edge and server deployments:

| Metric | Measurement |
| :--- | :--- |
| **Idle Memory Footprint** | ~40 MB – 65 MB RAM |
| **Under Sustained Load** | ~80 MB – 120 MB RAM |
| **Routing Latency Overhead** | < 1.2 ms |
| **Minimum Hardware Requirement** | 1 vCPU, 512 MB RAM, 200 MB Storage |
| **Supported OS Runtimes** | Linux (x64 / ARM64), macOS (Intel / Apple Silicon), Windows (x64) |

---

## 🚀 Installation

### 1. Linux / VPS (Systemd Service)

Deploy AtomicRouter as a persistent background daemon on Ubuntu, Debian, CentOS, Rocky Linux, or Arch Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | sudo bash
```

The installer automatically:
1. Detects and installs Node.js 22 LTS (if not present).
2. Deploys the pre-compiled standalone binary to `/opt/atomic-router`.
3. Generates unique 256-bit cryptographic keys for local session encryption.
4. Registers and starts the `atomic-router` systemd service on port `20128`.

---

### 2. Windows Standalone

#### Method A: 1-Line PowerShell Quickstart
Open **PowerShell** (Run as Administrator or Normal User):
```powershell
irm https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.ps1 | iex
```

#### Method B: Manual Archive Download
1. Download **`atomic-router-windows-x64.zip`** from [Latest Releases](https://github.com/dianrestu/atomic-router/releases/latest).
2. Extract the archive to your desired directory.
3. Double-click **`start.bat`**.
4. Navigate to **`http://localhost:20128/`** in your browser.

---

### 3. macOS Standalone

#### Method A: 1-Line Terminal Quickstart
```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | bash
```

#### Method B: Manual Extraction
1. Download **`atomic-router-macos-universal.tar.gz`** from [Latest Releases](https://github.com/dianrestu/atomic-router/releases/latest).
2. Extract and run:
   ```bash
   tar -xzf atomic-router-macos-universal.tar.gz -C ~/atomic-router
   cd ~/atomic-router
   ./start.sh
   ```
3. Open **`http://localhost:20128/`**.

---

### 4. Raspberry Pi & Linux ARM64

Compatible with Raspberry Pi 4/5, Orange Pi, AWS Graviton, and Ampere ARM64 instances:

```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | sudo bash
```

---

### 5. Android (Termux)

Run a local AI proxy directly on your Android device:

```bash
curl -fsSL https://raw.githubusercontent.com/dianrestu/atomic-router/main/install.sh | bash
```

---

## 🛠️ Management CLI (`atomic-router`)

When installed on Linux or Unix systems, manage your gateway with the `atomic-router` CLI:

```bash
# Update to the latest release (preserves 100% of databases, accounts, and combos)
sudo atomic-router update

# View live real-time request logs and traces
atomic-router logs

# Inspect gateway service status and uptime
atomic-router status

# Restart the service
sudo atomic-router restart

# Stop / Start service
sudo atomic-router stop
sudo atomic-router start
```

---

## 🔀 Smart Combos & Routing Strategies

Combos allow grouping multiple AI models under a single identifier (e.g. `smart-coding-combo`). AtomicRouter resolves which provider to invoke based on your selected strategy:

| Strategy | Behavior | Best Use Case |
| :--- | :--- | :--- |
| **`priority`** | Executes targets in exact declared sequence. | Primary / Backup failover cascades. |
| **`weighted`** | Routes traffic probabilistically based on percentage weights. | A/B testing and proportional provider distribution. |
| **`round-robin`** | Cycles requests sequentially across candidate models. | Load balancing across multiple high-throughput accounts. |
| **`least-used`** | Dispatches to the target with the lowest active/historical requests. | Maximizing rate-limit headroom. |
| **`auto`** | 14-factor runtime evaluation (latency, circuit breaker state, token quota). | Autonomous, self-optimizing multi-cloud routing. |
| **`fusion`** | Sends prompts to all candidates concurrently; merges responses via judge. | High-reliability reasoning and consensus validation. |

---

## 🔌 Client Integration Guides

### OpenAI Python SDK

Seamlessly redirect Python AI pipelines to AtomicRouter by configuring `base_url`:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:20128/v1",
    api_key="your-atomic-router-api-key",
)

# Standard model invocation
response = client.chat.completions.create(
    model="claude-3-7-sonnet-20250219",  # Or any configured combo name
    messages=[
        {"role": "system", "content": "You are a helpful software architect."},
        {"role": "user", "content": "Explain circuit breaker patterns in distributed systems."},
    ],
    temperature=0.7,
)

print(response.choices[0].message.content)
```

---

### Cursor / Cline / Roo Code

Integrate AtomicRouter with AI coding agents:

- **API Provider**: `OpenAI Compatible`
- **Base URL**: `http://<your-server-ip>:20128/v1`
- **API Key**: `Bearer <your-gateway-api-key>`
- **Model Name**: Any provider model (`gpt-4o`, `claude-3-7-sonnet`, `gemini-2.5-pro`) or custom combo name.

---

### LangChain & LlamaIndex

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    base_url="http://localhost:20128/v1",
    api_key="your-atomic-router-api-key",
    model="gemini-2.5-pro",
)

response = llm.invoke("Summarize the benefits of unified AI gateways.")
print(response.content)
```

---

### cURL

```bash
curl -X POST http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-atomic-router-api-key" \
  -d '{
    "model": "claude-3-7-sonnet-20250219",
    "messages": [{"role": "user", "content": "Hello AtomicRouter!"}],
    "stream": true
  }'
```

---

## ⚙️ Configuration & Security

AtomicRouter stores all configurations in a lightweight, transaction-safe SQLite database with WAL (Write-Ahead Logging) enabled.

### Environment Variables (`.env`)

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `PORT` | `20128` | HTTP listening port for dashboard and `/v1` endpoints. |
| `INITIAL_PASSWORD` | `CHANGEME` | Initial administrative dashboard password on fresh install. |
| `JWT_SECRET` | Auto-generated | Cryptographic secret used for session authentication tokens. |
| `OMNIROUTE_SECRET_KEY` | Auto-generated | AES-256 master key for database credential encryption at rest. |
| `BETTER_AUTH_SECRET` | Auto-generated | Local authentication middleware security seed. |

### Database Backup & Portability
- Navigate to **Dashboard → Settings → Backup & Restore**.
- Generate encrypted `.tar.gz` snapshots or raw SQLite backups to easily replicate setups across cloud environments.

---

## 📄 License

AtomicRouter is open-source software licensed under the **[MIT License](LICENSE)**.
