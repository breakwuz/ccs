# Claude Configuration Switcher (CCS)

A command-line tool for managing multiple Claude API configurations. Easily switch between different API keys and base URLs for various environments or accounts.

[中文版](README.md)

## Features

- **Configuration Management**: Store and manage multiple Claude API configurations
- **Easy Switching**: Switch between configurations with a single command
- **Template Support**: Use default templates to ensure consistent configuration structure
- **Configuration Protection**: Prevent deletion or modification of currently active configurations
- **Information Masking**: Automatically mask API keys when displayed to protect privacy
- **Validation**: Name validation and confirmation prompts for destructive operations
- **Multi-language**: Support for both Chinese and English interfaces
- **Beautiful Interface**: Colorized output and icons for enhanced user experience

## Installation

### Method 1: System-wide Installation (Recommended)
```bash
# Install to system directory
sudo install -m 755 ccs.sh /usr/local/bin/ccs

# Copy default template
cp settings-default.json ~/.claude/settings-default.json
# Or depending on your chosen naming format
cp settings.json.default ~/.claude/settings.json.default
```

## Usage

### Basic Commands

```bash
# Show current configuration and all configuration list (default behavior)
ccs
# or
ccs list
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
ccs modify [config_name] <new_key> <new_url>
# Modify currently active configuration (without specifying config name)
ccs modify sk-new-key https://new-api.com
# Modify specified configuration (cannot modify currently active configuration)
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

# Uninstall tool
ccs uninstall
```

### Usage Examples

```bash
# Add configurations for different environments
ccs add production sk-ant-prod-xxxxx https://api.anthropic.com
ccs add development sk-ant-dev-xxxxx https://api.anthropic.com  
ccs add custom sk-ant-custom-xxxxx https://custom.api.com

# View current status (default behavior)
ccs
# Output example (traditional format):
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

# Output example (new format):
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

# Modify non-active configuration
ccs modify production sk-new-prod-key https://new-api.com

# Modify currently active configuration
ccs modify sk-new-dev-key https://new-dev-api.com
```

## Protection Mechanisms

To prevent accidental operations, CCS provides the following protection mechanisms:

### Delete Protection
- **Cannot delete currently active configuration**
- Must switch to another configuration first before deletion
- Provides clear error messages and solutions

### Modify Protection  
- **Cannot modify backup file of currently active configuration** (when specified by config name)
- To modify currently active configuration, use: `ccs modify <new_key> <new_url>` (without config name)
- This ensures modifications are applied directly to the active configuration file

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

1. **Traditional format**: `~/.claude/settings.json.<name>`
2. **New format**: `~/.claude/settings-<name>.json`

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
      "Bash(mvn clean:*)",
      // ... other permissions
    ],
    "deny": []
  }
}
```

## Privacy Protection

- **API Key Masking**: Only shows first 12 and last 10 characters when displayed, with asterisks in between
- **Secure Storage**: Configuration files stored in user home directory with system-protected permissions

## Uninstall/Cleanup

### Complete Removal of Script and Configurations

```bash
# Use CCS built-in uninstall function to remove configuration files (selective deletion) (Recommended)
ccs uninstall

# Remove system-installed script
sudo rm -f /usr/local/bin/ccs

# Manually remove configuration files and default template (if needed)
rm -rf ~/.claude/settings.json.*
rm -rf ~/.claude/settings-*.json
rm -f ~/.claude/ccs.conf
```

## License

MIT License - See [LICENSE](LICENSE) file for details

## Repository

https://github.com/shuiyihan12/ccs