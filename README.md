# Claude Code 配置切换器 (CCS)

一个用于管理多个 Claude API 配置的命令行工具。可以轻松在不同环境或账户的 API 密钥和基础 URL 之间切换。

[English Version](README_EN.md)

## 功能特性

- **配置管理**: 存储和管理多个 Claude API 配置
- **简单切换**: 使用单个命令在配置间切换
- **模板支持**: 使用默认模板确保配置结构一致
- **配置保护**: 防止删除或修改当前激活的配置
- **信息脱敏**: API 密钥显示时自动脱敏保护隐私
- **验证**: 名称验证和破坏性操作的确认提示
- **多语言**: 支持中文和英文界面
- **美观界面**: 彩色输出和图标增强用户体验

## 安装

### 一键安装（推荐）

```bash
# 系统安装（推荐 - 使用镜像站）
curl -fsSL "https://cdn.jsdelivr.net/gh/shuiyihan12/ccs@master/ccs.sh" | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs

# 用户安装（无需 sudo - 使用镜像站）
curl -fsSL "https://cdn.jsdelivr.net/gh/shuiyihan12/ccs@master/ccs.sh" | \
install -D -m 755 /dev/stdin ~/bin/ccs && export PATH="$PATH:~/bin"

# 使用 GitHub 直链（备选方案）
curl -fsSL https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs

# 使用 wget（备选方案）
wget -qO- https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs
```

### 手动安装

```bash
# 下载脚本
wget https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh

# 安装到系统目录（推荐）
sudo install -m 755 ccs.sh /usr/local/bin/ccs

# 或者安装到用户目录（无需 sudo）
mkdir -p ~/bin
install -m 755 ccs.sh ~/bin/ccs
# 确保 ~/bin 在 PATH 中
export PATH="$PATH:~/bin"
``` 

## 使用方法

### 基础命令

```bash
# 显示帮助信息（默认行为）
ccs
# 或
ccs help

# 显示当前配置和所有配置列表
ccs list
# 或
ccs ls

# 添加新配置
ccs add <名称> <api_key> <base_url>
# 示例:
ccs add work sk-ant-xxxxx https://api.anthropic.com

# 切换到配置
ccs switch <名称>
# 或
ccs sw work

# 删除配置（无法删除当前激活的配置）
ccs delete <名称>
# 或
ccs del work
ccs rm work

# 重命名配置
ccs rename <旧名称> <新名称>
# 或
ccs mv old_name new_name

# 修改配置
ccs modify <配置名称> <新密钥> <新地址>
# 修改指定配置（只能修改非激活状态的配置）
ccs modify work sk-new-key https://new-api.com

# 设置配置模板
ccs template [配置名称]
# 使用当前配置作为模板
ccs template
# 使用指定配置作为模板
ccs template work

# 显示版本信息
ccs version

# 显示帮助
ccs help

# 卸载工具
ccs uninstall
```

### 使用示例

```bash
# 添加不同环境配置
ccs add production sk-ant-prod-xxxxx https://api.anthropic.com
ccs add development sk-ant-dev-xxxxx https://api.anthropic.com  
ccs add custom sk-ant-custom-xxxxx https://custom.api.com

# 查看当前状态
ccs list
# 输出示例（新格式）:
# 🔄 当前配置：
#   ✓ production (settings.json.production) (激活)
# 
# ⚙️ 可用配置：
#   • development (settings.json.development)
#     ➤ Base URL: https://api.anthropic.com
#     ➤ API Key:  sk-ant-****xxxxx
# 
#   ✓ production (settings.json.production) (激活)
#     ➤ Base URL: https://api.anthropic.com  
#     ➤ API Key:  sk-ant-****xxxxx
# 
#   • custom (settings.json.custom)
#     ➤ Base URL: https://custom.api.com
#     ➤ API Key:  sk-ant-****xxxxx

# 输出示例（传统格式）:
# 🔄 当前配置：
#   ✓ production (settings-production.json) (激活)
# 
# ⚙️ 可用配置：
#   • development (settings-development.json)
#     ➤ Base URL: https://api.anthropic.com
#     ➤ API Key:  sk-ant-****xxxxx
#     ➤ API Key:  sk-ant-****xxxxx

# 切换到开发环境
ccs switch development
# 输出:
# ✅ 已切换到配置: development
# ⚠️ 重要提醒：请重启 Claude Code 以使更改生效。

# 尝试删除当前激活的配置（会被阻止）
ccs delete development
# 输出:
# ❌ 错误：无法删除当前激活的配置 'development'
# ℹ️ 请先切换到其他配置，使用：ccs switch <其他配置>

# 修改非激活配置（然后可以切换过去）
ccs modify production sk-new-prod-key https://new-api.com

# 不能修改当前激活配置（因为Claude Code需要重启才能生效）
```

## 保护机制

为了防止误操作，CCS 提供了以下保护机制：

### 删除保护
- **无法删除当前激活的配置**
- 必须先切换到其他配置才能删除
- 提供清晰的错误提示和解决方案

### 修改保护  
- **无法修改当前激活的配置**：因为Claude Code需要重启才能读取配置文件更改
- **只能修改非激活状态的配置**：修改后切换到该配置时立即生效
- **建议工作流程**：修改非激活配置 → 切换到该配置 → 重启Claude Code

## 语言支持

CCS 工具支持中英文界面，通过配置文件 `~/.claude/ccs.conf` 设置默认语言。首次使用时会引导您选择语言偏好。

```bash
# 首次使用时会出现语言选择提示
ccs help

# 配置文件中的语言设置
# ~/.claude/ccs.conf
default_language=zh  # 或 en
```

默认语言设置后，所有命令都会使用该语言显示信息。

## 配置格式

工具支持两种配置文件命名格式，用户可在首次使用时选择：

1. **新格式**：`~/.claude/settings.json.<配置名称>` [默认]
2. **传统格式**：`~/.claude/settings-<配置名称>.json`

配置文件具有以下结构的 JSON 格式：

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "your_api_key_here",
    "ANTHROPIC_BASE_URL": "your_base_url_here",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "DISABLE_TELEMETRY": 1
  },
  "includeCoAuthoredBy": false,
  "permissions": {
    "allow": [
      "Bash(find:*)",
      "Bash(mvn clean:*)"
    ],
    "deny": []
  }
}
```

## 隐私保护

- **API 密钥脱敏**: 显示时只显示前12位和后10位，中间用星号代替
- **安全存储**: 配置文件存储在用户主目录下，权限受系统保护

## 卸载/清理

### 完全删除脚本和配置

```bash
# 使用 CCS 内置卸载功能删除配置文件（可选择性删除）（推荐）
ccs uninstall

# 删除系统安装的脚本
sudo rm -f /usr/local/bin/ccs

# 手动删除配置文件和默认模板（如需要）
rm -rf ~/.claude/settings.json.*
rm -rf ~/.claude/settings-*.json
rm -f ~/.claude/ccs.conf
```