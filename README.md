# OpenClaw Control - Apple 原生控制面板

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20visionOS-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
</p>

Apple 全平台原生应用，用于控制 OpenClaw 助手。

## ✨ 功能

### 📱 iOS / 🖥️ macOS
- 💬 实时聊天 - 发送和接收消息
- 📊 数据看板 - 查看系统状态、Token 使用量、活跃会话
- 👥 会话管理 - 查看和管理所有会话
- ⚙️ 灵活配置 - 支持多种连接方式

### ⌚ watchOS
- 📋 快速查看连接状态
- 👁️ 核心指标一目了然

### 🥽 visionOS
- 🖥️ MR 体验 - 空间计算支持
- 📊 多视图切换 - 状态/聊天/会话

---

## 🔗 连接方案

### 方案 1: 有公网

如果你有公网 IP 或域名：

```
配置 → 服务器地址: https://your-domain.com:18789
```

**推荐**: 使用 HTTPS + 域名，配合 Let's Encrypt 免费证书。

### 方案 2: 无公网 (推荐)

#### Tailscale (最佳方案)
1. 在运行 OpenClaw 的机器上安装 [Tailscale](https://tailscale.com)
2. 在 Apple 设备上登录同一 Tailscale 账号
3. 获取 Tailscale 分配的 IP (通常是 100.x.x.x)
4. 配置: `http://100.x.x.x:18789`

**优点**: 免费、简单、安全、内网穿透

#### Cloudflare Tunnel
1. 安装 [cloudflared](https://github.com/cloudflare/cloudflared)
2. 配置 Tunnel 指向 OpenClaw
3. 使用分配的域名访问

#### VPN/内网穿透
- [frp](https://github.com/fatedier/frp)
- [natapp](https://natapp.cn/)
- [ngrok](https://ngrok.com/)

---

## 🛠️ 安装

### 方式 1: Xcode 编译

```bash
# 克隆项目
git clone https://github.com/your-repo/OpenClawControl.git
cd OpenClawControl

# 用 Xcode 打开
open OpenClawControl.xcodeproj
```

1. 选择你的开发者账号
2. 选择目标设备 (iPhone/Mac/Apple Watch/Vision Pro)
3. Build & Run

### 方式 2: 命令行

```bash
xcodebuild -project OpenClawControl.xcodeproj \
  -scheme OpenClawControl \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

---

## 📁 项目结构

```
OpenClawControl/
├── Package.swift              # Swift Package 配置
├── Sources/
│   ├── App/                   # App 入口
│   ├── Models/                # 数据模型
│   ├── Services/              # API 服务
│   ├── ViewModels/            # 业务逻辑
│   └── Views/                 # UI 视图
├── Watch/                     # watchOS App
│   ├── App/
│   └── Extension/
└── Vision/                    # visionOS App
    └── App/
```

---

## 🔧 配置说明

首次使用时需要在 App 内配置服务器地址：

| 字段 | 说明 |
|------|------|
| 连接方式 | 本地网络 / Tailscale / VPN / 公网 |
| 服务器地址 | 例如: `http://192.168.1.100:18789` |
| 认证 Token | OpenClaw Gateway 的认证令牌 |

---

## 📋 API 参考

App 通过以下 OpenClaw API 进行通信：

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/status` | GET | 获取系统状态 |
| `/api/sessions` | GET | 获取会话列表 |
| `/api/sessions/:key/messages` | GET | 获取消息 |
| `/api/message` | POST | 发送消息 |

---

## 🤝 贡献

欢迎提交 Issue 和 PR！

## 📄 许可证

MIT License
