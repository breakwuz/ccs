# Claude Code Configuration Switcher (CCS)

A command-line tool for managing multiple Claude API configurations. Easily switch between different API keys and base URLs for various environments or accounts.

[中文版](README.md)

## Features

- **Configuration Management**: Store and manage multiple Claude API configurations
- **Easy Switching**: Switch between configurations with a single command
- **Template Support**: Use default templates to ensure consistent configuration structure
- **Configuration Protection**: Prevent deletion or modification of currently active configurations
- **Information Sanitization**: Automatically sanitize API keys when displayed to protect privacy
- **Validation**: Name validation and confirmation prompts for destructive operations
- **Multi-language**: Support for both Chinese and English interfaces
- **Beautiful Interface**: Colorized output and icons for enhanced user experience
- **Auto Update**: Built-in auto-update functionality to keep the tool up-to-date

## Installation

### One-liner Installation (Recommended)

```bash
# System installation (recommended - using CDN mirror)
curl -fsSL "https://cdn.jsdelivr.net/gh/shuiyihan12/ccs@master/ccs.sh" | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs

# User installation (no sudo required - using CDN mirror)
curl -fsSL "https://cdn.jsdelivr.net/gh/shuiyihan12/ccs@master/ccs.sh" | \
install -D -m 755 /dev/stdin ~/bin/ccs && export PATH="$PATH:~/bin"

# Using GitHub direct link (alternative option)
curl -fsSL https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs

# Using wget (alternative option)
wget -qO- https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh | \
sudo tee /usr/local/bin/ccs > /dev/null && sudo chmod +x /usr/local/bin/ccs
```

### Manual Installation

```bash
# Download script
wget https://raw.githubusercontent.com/shuiyihan12/ccs/refs/heads/master/ccs.sh

# Install to system directory (recommended)
sudo install -m 755 ccs.sh /usr/local/bin/ccs

# Or install to user directory (no sudo required)
mkdir -p ~/bin
install -m 755 ccs.sh ~/bin/ccs
# Ensure ~/bin is in PATH
export PATH="$PATH:~/bin"
```

## Usage

### Basic Commands

```bash
# Show help information (default behavior)
ccs
# or
ccs help

# Show current configuration and all configuration list
ccs list
# or
ccs ls

# Add new configuration
ccs add <name> <api_key> <base_url>
# Example:
ccs add work sk-ant-xxxxx https://api.anthropic.com

# Switch to configuration
ccs switch <name>
# or
ccs sw work

# Delete configuration (cannot delete currently active configuration)
ccs delete <name>
# or
ccs del work
ccs rm work

# Rename configuration
ccs rename <old_name> <new_name>
# or
ccs mv old_name new_name

# Modify configuration
ccs modify <config_name> <new_key> <new_url>
# Modify specified configuration (can only modify non-active configurations)
ccs modify work sk-new-key https://new-api.com

# Set configuration template
ccs template [config_name]
# Use current configuration as template
ccs template
# Use specified configuration as template
ccs template work

# Show version information
ccs version

# Show help
ccs help

# Update to latest version
ccs update

# Uninstall tool
ccs uninstall
```

### Auto Update

```bash
# Check and update to latest version
ccs update
# System will automatically check version, and ask if you want to upgrade if updates are available (default choice is yes)

# If there are issues after update, you can rollback to previous version
ccs update --rollback
```

### Usage Examples

```bash
# Add configurations for different environments
ccs add production sk-ant-prod-xxxxx https://api.anthropic.com
ccs add development sk-ant-dev-xxxxx https://api.anthropic.com  
ccs add custom sk-ant-custom-xxxxx https://custom.api.com

# View current status
ccs list
# Output example (new format):
# 🔄 Current Configuration:
#   ✓ production (settings.json.production) (Active)
# 
# ⚙️ Available Configurations:
#   • development (settings.json.development)
#     ➤ Base URL: https://api.anthropic.com
#     ➤ API Key:  sk-ant-****xxxxx
# 
#   ✓ production (settings.json.production) (Active)
#     ➤ Base URL: https://api.anthropic.com  
#     ➤ API Key:  sk-ant-****xxxxx
# 
#   • custom (settings.json.custom)
#     ➤ Base URL: https://custom.api.com
#     ➤ API Key:  sk-ant-****xxxxx

# Output example (traditional format):
# 🔄 Current Configuration:
#   ✓ production (settings-production.json) (Active)
# 
# ⚙️ Available Configurations:
#   • development (settings-development.json)
#     ➤ Base URL: https://api.anthropic.com
#     ➤ API Key:  sk-ant-****xxxxx

# Switch to development environment
ccs switch development
# Output:
# ✅ Switched to configuration: development
# ⚠️ Important: Please restart Claude Code for the changes to take effect.

# Try to delete currently active configuration (will be blocked)
ccs delete development
# Output:
# ❌ Error: Cannot delete the currently active configuration 'development'
# ℹ️ Please switch to another configuration first using: ccs switch <other_config>

# Modify non-active configuration (then can switch to it)
ccs modify production sk-new-prod-key https://new-api.com

# Cannot modify currently active configuration (because Claude Code needs restart to take effect)
```

## Protection Mechanisms

To prevent accidental operations, CCS provides the following protection mechanisms:

### Delete Protection
- **Cannot delete currently active configuration**
- Must switch to another configuration first before deletion
- Provides clear error messages and solutions

### Modification Protection  
- **Cannot modify currently active configuration**: Because Claude Code needs restart to read configuration file changes
- **Can only modify non-active configurations**: Changes take effect immediately when switching to that configuration
- **Suggested workflow**: Modify non-active configuration → Switch to that configuration → Restart Claude Code

## Language Support

CCS tool supports both Chinese and English interfaces, with default language set through the configuration file `~/.claude/ccs.conf`. First-time usage will guide you to choose your language preference.

```bash
# Language selection prompt will appear on first use
ccs help

# Language setting in configuration file
# ~/.claude/ccs.conf
default_language=zh  # or en
```

Once default language is set, all commands will display information in that language.

## Configuration Format

The tool supports two configuration file naming formats, which users can choose during first-time setup:

1. **New format**: `~/.claude/settings.json.<config_name>` [default]
2. **Traditional format**: `~/.claude/settings-<config_name>.json`

Configuration files have the following JSON structure:

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

## Privacy Protection

- **API Key Sanitization**: Only shows first 12 and last 10 characters when displayed, middle replaced with asterisks
- **Secure Storage**: Configuration files stored in user home directory with system-protected permissions

## Uninstall/Cleanup

### Complete Removal of Script and Configurations

```bash
# Use CCS built-in uninstall function to remove configuration files (selective deletion) (Recommended)
ccs uninstall

# Remove system-installed script
sudo rm -f /usr/local/bin/ccs

# Manually delete configuration files and default template (if needed)
rm -rf ~/.claude/settings.json.*
rm -rf ~/.claude/settings-*.json
rm -f ~/.claude/ccs.conf
```