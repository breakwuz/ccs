#!/bin/bash

# Claude Configuration Switcher (ccs)
# 管理 ~/.claude/settings.json 配置文件的切换工具
# Manages ~/.claude/settings.json configurations

# 版本信息
# Version information
CCS_VERSION="1.0.0"

# 常量定义
# Constants
DEFAULT_LANGUAGE="zh"
DEFAULT_NAMING_CONVENTION="suffix"  # "suffix" for settings.json.<name>, "prefix" for settings-<name>.json
ANTHROPIC_API_KEY_FIELD="ANTHROPIC_API_KEY"
ANTHROPIC_BASE_URL_FIELD="ANTHROPIC_BASE_URL"
SETTINGS_FILE_PATTERN="settings-.*\.json"
API_KEY_PLACEHOLDER="your_api_key_here"
BASE_URL_PLACEHOLDER="your_base_url_here"
REPOSITORY_URL="https://github.com/shuiyihan12/ccs"
LICENSE="MIT"
AUTHOR="shiuyihan"
SEPARATOR_LINE="────────────────────────────────────────────────"

# 提示信息常量
# Prompt message constants
SETUP_LANGUAGE_PROMPT_ZH="请输入选项 / Enter choice (1/2) [默认: 1]: "
SETUP_NAMING_PROMPT_ZH="请输入选项 / Enter choice (1/2) [默认: 1]: "
DEFAULT_SELECTED_ZH="已选择默认选项:"
DEFAULT_SELECTED_EN="Selected default option:"

# 更新相关常量 (Update related constants)
GITHUB_API_URL="https://api.github.com/repos/shuiyihan12/ccs/releases/latest"
GITHUB_RAW_URL="https://raw.githubusercontent.com/shuiyihan12/ccs/master/ccs.sh"
CDN_MIRROR_URL="https://cdn.jsdelivr.net/gh/shuiyihan12/ccs@master/ccs.sh"
SCRIPT_BACKUP_SUFFIX=".backup"

# 默认模板内容 (Default template content)
DEFAULT_TEMPLATE_CONTENT='{
  "env": {
    "ANTHROPIC_API_KEY": "your_api_key_here",
    "ANTHROPIC_BASE_URL": "your_base_url_here",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "DISABLE_TELEMETRY": 1
  },
  "includeCoAuthoredBy": false,
  "permissions": {
    "allow": [],
    "deny": []
  }
}'

# 颜色常量 (Colors)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 图标常量 (Icons)
ICON_CHECK="✓"
ICON_ARROW="➤"
ICON_STAR="★"
ICON_DOT="•"
ICON_CONFIG="⚙️"
ICON_ACTIVE="🔄"
ICON_INFO="ℹ️"
ICON_WARNING="⚠️"
ICON_ERROR="❌"
ICON_SUCCESS="✅"

# 表格相关常量 (Table Constants)
TABLE_BORDER_TOP="┌"
TABLE_BORDER_BOTTOM="└"
TABLE_BORDER_MIDDLE="├"
TABLE_BORDER_RIGHT="┐"
TABLE_BORDER_BOTTOM_RIGHT="┘"
TABLE_BORDER_MIDDLE_RIGHT="┤"
TABLE_HORIZONTAL="─"
TABLE_VERTICAL="│"
TABLE_CROSS="┼"

# 全局变量缓存
# Global variable cache
_CACHED_LANGUAGE=""
_CACHED_NAMING_CONVENTION=""
_CACHED_CURRENT_CONFIG=""

# 获取并缓存用户配置
# Get and cache user configuration
get_cached_config() {
    local config_key="$1"
    
    case "$config_key" in
        "default_language")
            if [[ -z "$_CACHED_LANGUAGE" ]]; then
                _CACHED_LANGUAGE=$(read_user_config "default_language")
                if [[ -z "$_CACHED_LANGUAGE" ]]; then
                    _CACHED_LANGUAGE="$DEFAULT_LANGUAGE"
                fi
            fi
            echo "$_CACHED_LANGUAGE"
            ;;
        "naming_convention")
            if [[ -z "$_CACHED_NAMING_CONVENTION" ]]; then
                _CACHED_NAMING_CONVENTION=$(read_user_config "naming_convention")
                if [[ -z "$_CACHED_NAMING_CONVENTION" ]]; then
                    _CACHED_NAMING_CONVENTION="$DEFAULT_NAMING_CONVENTION"
                fi
            fi
            echo "$_CACHED_NAMING_CONVENTION"
            ;;
        "current_config")
            if [[ -z "$_CACHED_CURRENT_CONFIG" ]]; then
                _CACHED_CURRENT_CONFIG=$(read_user_config "current_config")
            fi
            echo "$_CACHED_CURRENT_CONFIG"
            ;;
    esac
}

# 清除配置缓存
# Clear configuration cache
clear_config_cache() {
    _CACHED_LANGUAGE=""
    _CACHED_NAMING_CONVENTION=""
    _CACHED_CURRENT_CONFIG=""
}

# 配置目录和文件路径
# Configuration directory and file paths
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CCS_CONFIG_FILE="$CLAUDE_DIR/ccs.conf"

# 生成默认模板文件路径
# Generate default template file path
get_default_file_path() {
    local naming_convention=$(get_cached_config "naming_convention")
    
    case "$naming_convention" in
        "prefix")
            echo "$CLAUDE_DIR/settings-default.json"
            ;;
        "suffix"|*)
            echo "$CLAUDE_DIR/settings.json.default"
            ;;
    esac
}

# 创建默认模板文件
# Create default template file
create_default_template() {
    local default_file_path="$(get_default_file_path)"
    
    # 创建目录（如果不存在）
    # Create directory if it doesn't exist
    mkdir -p "$CLAUDE_DIR"
    
    # 创建默认模板文件
    # Create default template file
    echo "$DEFAULT_TEMPLATE_CONTENT" > "$default_file_path"
    
    return 0
}

# 通用错误消息函数
# Generic error message function
show_message() {
    local lang="$1"
    local en_msg="$2"
    local zh_msg="$3"
    if [[ "$lang" == "en" ]]; then
        echo "$en_msg"
    else
        echo "$zh_msg"
    fi
}

# 用户确认提示函数
# User confirmation prompt function
confirm_action() {
    local lang="$1"
    local en_prompt="$2"
    local zh_prompt="$3"
    if [[ "$lang" == "en" ]]; then
        read -p "$en_prompt (y/N): " -n 1 -r
    else
        read -p "$zh_prompt (y/N): " -n 1 -r
    fi
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# 更新确认提示函数（默认Y）
# Update confirmation prompt function (default Y)
confirm_update() {
    local lang="$1"
    local en_prompt="$2"
    local zh_prompt="$3"
    if [[ "$lang" == "en" ]]; then
        read -p "$en_prompt (Y/n): " -n 1 -r
    else
        read -p "$zh_prompt (Y/n): " -n 1 -r
    fi
    echo
    # 默认为Y，只有明确输入n/N才拒绝
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
    else
        return 0
    fi
}

# 生成配置文件路径
# Generate configuration file path
get_config_file_path() {
    local name="$1"
    local naming_convention=$(get_cached_config "naming_convention")
    
    case "$naming_convention" in
        "prefix")
            echo "$CLAUDE_DIR/settings-$name.json"
            ;;
        "suffix"|*)
            echo "$CLAUDE_DIR/settings.json.$name"
            ;;
    esac
}

# 生成文件模式匹配pattern
# Generate file pattern for matching
get_file_pattern() {
    local naming_convention=$(get_cached_config "naming_convention")
    
    case "$naming_convention" in
        "prefix")
            echo "settings-.*\\.json"
            ;;
        "suffix"|*)
            echo "settings\\.json\\..*"
            ;;
    esac
}

# 提取配置名称函数
# Extract configuration name function
extract_config_name() {
    local file="$1"
    local filename=$(basename "$file")
    local naming_convention=$(get_cached_config "naming_convention")
    
    case "$naming_convention" in
        "prefix")
            # 从 settings-<name>.json 格式中提取 <name>
            # Extract <name> from settings-<name>.json format
            echo "$filename" | sed 's/^settings-\(.*\)\.json$/\1/'
            ;;
        "suffix"|*)
            # 从 settings.json.<name> 格式中提取 <name>
            # Extract <name> from settings.json.<name> format
            echo "$filename" | sed 's/^settings\.json\.\(.*\)$/\1/'
            ;;
    esac
}

# 生成空格函数（优化版本）
# Generate spaces function (optimized version)
generate_spaces() {
    local count="$1"
    printf "%*s" "$count" ""
}

# 检查配置文件是否存在
# Check if configuration file exists
check_config_exists() {
    local name="$1"
    local backup_file="$(get_config_file_path "$name")"
    
    if [[ ! -f "$backup_file" ]]; then
        handle_error "missing_config" "$name"
        return 1
    fi
    return 0
}

# 获取配置文件信息（文件名和配置名）
# Get configuration file info (filename and config name)
get_config_info() {
    local file="$1"
    local filename=$(basename "$file")
    local config_name=$(extract_config_name "$file")
    echo "${filename}|${config_name}"
}

# 读取用户配置
read_user_config() {
    local default_lang="zh"
    local naming_convention="suffix"
    local current_config=""
    
    if [[ -f "$CCS_CONFIG_FILE" ]]; then
        # 读取配置文件
        # Read configuration file
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            
            case "$key" in
                "default_language")
                    default_lang="$value"
                    ;;
                "naming_convention")
                    naming_convention="$value"
                    ;;
                "current_config")
                    current_config="$value"
                    ;;
            esac
        done < "$CCS_CONFIG_FILE"
    fi
    
    # 输出配置值
    # Output configuration values
    case "$1" in
        "default_language")
            echo "$default_lang"
            ;;
        "naming_convention")
            echo "$naming_convention"
            ;;
        "current_config")
            echo "$current_config"
            ;;
    esac
}

# 简单的版本比较函数
# Simple version comparison function
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 移除版本号前的v字符
    version1="${version1#v}"
    version2="${version2#v}"
    
    # 使用点分割版本号
    IFS='.' read -ra VER1 <<< "$version1"
    IFS='.' read -ra VER2 <<< "$version2"
    
    # 比较主要版本号
    local v1_major=${VER1[0]:-0}
    local v2_major=${VER2[0]:-0}
    local v1_minor=${VER1[1]:-0}
    local v2_minor=${VER2[1]:-0}
    local v1_patch=${VER1[2]:-0}
    local v2_patch=${VER2[2]:-0}
    
    if [[ $v1_major -gt $v2_major ]]; then
        return 1  # version1 > version2
    elif [[ $v1_major -lt $v2_major ]]; then
        return 2  # version1 < version2
    elif [[ $v1_minor -gt $v2_minor ]]; then
        return 1
    elif [[ $v1_minor -lt $v2_minor ]]; then
        return 2
    elif [[ $v1_patch -gt $v2_patch ]]; then
        return 1
    elif [[ $v1_patch -lt $v2_patch ]]; then
        return 2
    fi
    
    return 0  # version1 == version2
}

# 获取远程版本号（直接从CDN获取）
# Get remote version (directly from CDN)
get_remote_version() {
    # 检查curl是否可用
    if ! command -v curl &> /dev/null; then
        return 1
    fi
    
    # 直接从CDN获取版本号
    local remote_version
    remote_version=$(curl -fsSL "$CDN_MIRROR_URL" | grep '^CCS_VERSION=' | head -1 | cut -d'"' -f2)
    
    if [[ -z "$remote_version" ]]; then
        return 1
    fi
    
    # 返回版本号
    echo "$remote_version"
    return 0
}

# 下载远程文件到临时文件并返回路径
# Download remote file to temporary file and return path
download_remote_file() {
    # 检查curl是否可用
    if ! command -v curl &> /dev/null; then
        return 1
    fi
    
    # 创建临时文件
    local temp_file=$(mktemp)
    if [[ -z "$temp_file" ]]; then
        return 1
    fi
    
    # 下载到临时文件
    if ! curl -fsSL "$CDN_MIRROR_URL" -o "$temp_file"; then
        rm -f "$temp_file"
        return 1
    fi
    
    # 检查文件是否为空
    if [[ ! -s "$temp_file" ]]; then
        rm -f "$temp_file"
        return 1
    fi
    
    # 返回临时文件路径
    echo "$temp_file"
    return 0
}

# 获取当前脚本的路径
# Get current script path
get_script_path() {
    local script_path=""
    
    # 首先尝试从 $0 获取
    # First try to get from $0
    if [[ -f "$0" ]]; then
        script_path="$0"
    # 检查常见安装位置
    # Check common installation locations
    elif [[ -f "/usr/local/bin/ccs" ]]; then
        script_path="/usr/local/bin/ccs"
    elif [[ -f "$HOME/bin/ccs" ]]; then
        script_path="$HOME/bin/ccs"
    elif [[ -f "./ccs.sh" ]]; then
        script_path="./ccs.sh"
    else
        # 尝试使用 which 命令
        # Try using which command
        script_path=$(which ccs 2>/dev/null)
    fi
    
    echo "$script_path"
}

# 写入用户配置
# Write user configuration
write_user_config() {
    local key="$1"
    local value="$2"
    
    # 创建目录（如果不存在）
    # Create directory if it doesn't exist
    mkdir -p "$CLAUDE_DIR"
    
    # 初始化配置文件（如果不存在）
    if [[ ! -f "$CCS_CONFIG_FILE" ]]; then
        cat > "$CCS_CONFIG_FILE" << 'EOF'
# CCS Configuration File
# CCS 配置文件

# Default language (zh/en)
# 默认语言 (zh/en)
default_language=zh

# File naming convention (suffix/prefix)
# 文件命名规则 (suffix/prefix)
# suffix: settings.json.<name>
# prefix: settings-<name>.json
naming_convention=suffix

# Current configuration name
# 当前配置名称
current_config=
EOF
    fi
    
    # 更新配置值并清除缓存
    # Update configuration value and clear cache
    if grep -q "^$key=" "$CCS_CONFIG_FILE"; then
        # 使用临时文件更新配置
        # Use temporary file to update configuration
        local temp_file=$(mktemp)
        while IFS= read -r line; do
            # 检查是否是要更新的配置行
            # Check if this is the configuration line to update
            if [[ "$line" =~ ^$key= ]]; then
                echo "$key=$value"
            else
                echo "$line"
            fi
        done < "$CCS_CONFIG_FILE" > "$temp_file"
        mv "$temp_file" "$CCS_CONFIG_FILE"
    else
        # 添加新的配置项
        # Add new configuration item
        echo "$key=$value" >> "$CCS_CONFIG_FILE"
    fi
    
    # 清除缓存以确保下次读取最新值
    # Clear cache to ensure next read gets latest values
    clear_config_cache
}

# 美化标题显示函数
# Beautiful title display function
display_title() {
    local title="$1"
    local width=60
    local title_length=${#title}
    local total_padding=$((width - title_length))
    local left_padding=$((total_padding / 2))
    local right_padding=$((total_padding - left_padding))
    local line=""
    
    # 生成分隔线
    for ((i=0; i<width; i++)); do
        line+="="
    done
    
    echo -e "${CYAN}$line${NC}"
    printf "${CYAN}%*s%s%*s${NC}\n" $left_padding "" "$title" $right_padding ""
    echo -e "${CYAN}$line${NC}"
}

# 第一次使用语言选择引导
# First-time language selection guide
first_time_setup() {
    if [[ ! -f "$CCS_CONFIG_FILE" ]]; then
        # 创建目录
        # Create directory
        mkdir -p "$CLAUDE_DIR"
        
        display_title "Claude Configuration Switcher (CCS) v$CCS_VERSION"
        echo ""
        
        echo "请选择您的默认语言 / Please choose your default language:"
        echo "1) 中文 (Chinese) [默认/Default]"
        echo "2) English"
        echo ""
        
        local lang_choice
        while true; do
            read -p "$SETUP_LANGUAGE_PROMPT_ZH" lang_choice
            # 如果没有输入，默认选择中文
            # If no input, default to Chinese
            if [[ -z "$lang_choice" ]]; then
                lang_choice="1"
                echo "$DEFAULT_SELECTED_ZH 1) 中文 (Chinese)"
                echo "$DEFAULT_SELECTED_EN 1) Chinese"
            fi
            
            case "$lang_choice" in
                "1")
                    write_user_config "default_language" "zh"
                    echo ""
                    echo "已设置中文为默认语言。"
                    echo "Chinese has been set as default language."
                    break
                    ;;
                "2")
                    write_user_config "default_language" "en"
                    echo ""
                    echo "English has been set as default language."
                    echo "英文已设置为默认语言。"
                    break
                    ;;
                *)
                    echo "无效选择，请输入 1 或 2（直接按回车默认选择中文）"
                    echo "Invalid choice, please enter 1 or 2 (press Enter for default Chinese)"
                    ;;
            esac
        done
        
        echo ""
        echo "请选择配置文件命名规则 / Please choose configuration file naming convention:"
        echo "1) settings.json.<名称> / settings.json.<name> [新格式 / New format] [默认/Default]"
        echo "2) settings-<名称>.json / settings-<name>.json [传统格式 / Traditional format]"
        echo ""
        
        local naming_choice
        while true; do
            read -p "$SETUP_NAMING_PROMPT_ZH" naming_choice
            # 如果没有输入，默认选择新格式
            # If no input, default to new format
            if [[ -z "$naming_choice" ]]; then
                naming_choice="1"
                echo "$DEFAULT_SELECTED_ZH 1) settings.json.<名称> / settings.json.<name>"
                echo "$DEFAULT_SELECTED_EN 1) settings.json.<name>"
            fi
            
            case "$naming_choice" in
                "1")
                    write_user_config "naming_convention" "suffix"
                    if [[ "$lang_choice" == "zh" ]]; then
                        echo ""
                        echo "已选择新命名格式: settings.json.<名称>"
                    else
                        echo ""
                        echo "Selected new naming format: settings.json.<name>"
                    fi
                    break
                    ;;
                "2")
                    write_user_config "naming_convention" "prefix"
                    if [[ "$lang_choice" == "zh" ]]; then
                        echo ""
                        echo "已选择传统命名格式: settings-<名称>.json"
                    else
                        echo ""
                        echo "Selected traditional naming format: settings-<name>.json"
                    fi
                    break
                    ;;
                *)
                    echo "无效选择，请输入 1 或 2（直接按回车默认选择新格式）"
                    echo "Invalid choice, please enter 1 or 2 (press Enter for default new format)"
                    ;;
            esac
        done
        
        echo ""
        display_title "设置完成 / Setup Complete"
        
        local default_lang=$(read_user_config "default_language")
        if [[ "$default_lang" == "zh" ]]; then
            echo "设置完成！使用 'ccs help' 查看帮助信息。"
            echo "正在创建默认模板文件..."
        else
            echo "Setup complete! Use 'ccs help' to see help information."
            echo "Creating default template file..."
        fi
        
        # 创建默认模板文件
        # Create default template file
        create_default_template
        
        local default_file_path="$(get_default_file_path)"
        if [[ "$default_lang" == "zh" ]]; then
            echo "默认模板文件已创建: $(basename "$default_file_path")"
        else
            echo "Default template file created: $(basename "$default_file_path")"
        fi
        echo ""
        
        # 确保配置缓存是最新的
        # Ensure configuration cache is up-to-date
        clear_config_cache
    fi
}

# 获取语言配置
# Get language configuration
get_language() {
    echo $(get_cached_config "default_language")
}

# 截断和脱敏API信息
# Truncate and sanitize API information
sanitize_api_info() {
    local info="$1"
    
    if [[ -z "$info" || "$info" == "null" ]]; then
        echo "N/A"
        return
    fi
    
    # 脱敏处理：显示前12位和后10位，中间用星号代替
    # Sanitize: show first 12 and last 10 characters, replace middle with asterisks
    if [[ ${#info} -gt 22 ]]; then
        local prefix="${info:0:12}"
        local suffix="${info: -10}"
        echo "${prefix}****${suffix}"
    elif [[ ${#info} -gt 16 ]]; then
        local prefix="${info:0:6}"
        local suffix="${info: -4}"
        echo "${prefix}****${suffix}"
    elif [[ ${#info} -gt 10 ]]; then
        local prefix="${info:0:4}"
        local suffix="${info: -3}"
        echo "${prefix}***${suffix}"
    else
        echo "$info"
    fi
}

# 截断文本到指定长度
# Truncate text to specified length
truncate_text() {
    local text="$1"
    local max_length="$2"
    
    if [[ ${#text} -le $max_length ]]; then
        echo "$text"
    else
        echo "${text:0:$((max_length-3))}..."
    fi
}

# 格式化表格单元格
# Format table cell with padding
format_table_cell() {
    local content="$1"
    local width="$2"
    local align="${3:-left}"  # left, right, center
    
    local content_length=${#content}
    local padding=$((width - content_length))
    
    if [[ $padding -lt 0 ]]; then
        padding=0
        content=$(truncate_text "$content" "$width")
    fi
    
    case "$align" in
        "right")
            printf "%*s%s" $padding "" "$content"
            ;;
        "center")
            local left_pad=$((padding / 2))
            local right_pad=$((padding - left_pad))
            printf "%*s%s%*s" $left_pad "" "$content" $right_pad ""
            ;;
        *)  # left (default)
            printf "%s%*s" "$content" $padding ""
            ;;
    esac
}

# 生成表格分隔线
# Generate table separator line
generate_table_separator() {
    local col_widths=("$@")
    local line=""
    
    line+="$TABLE_BORDER_MIDDLE"
    for i in "${!col_widths[@]}"; do
        for ((j=0; j<${col_widths[i]}+2; j++)); do
            line+="$TABLE_HORIZONTAL"
        done
        if [[ $i -lt $((${#col_widths[@]} - 1)) ]]; then
            line+="$TABLE_CROSS"
        fi
    done
    line+="$TABLE_BORDER_MIDDLE_RIGHT"
    
    echo "$line"
}

# 生成表格顶部边框
# Generate table top border
generate_table_top_border() {
    local col_widths=("$@")
    local line=""
    
    line+="$TABLE_BORDER_TOP"
    for i in "${!col_widths[@]}"; do
        for ((j=0; j<${col_widths[i]}+2; j++)); do
            line+="$TABLE_HORIZONTAL"
        done
        if [[ $i -lt $((${#col_widths[@]} - 1)) ]]; then
            line+="$TABLE_CROSS"
        fi
    done
    line+="$TABLE_BORDER_RIGHT"
    
    echo "$line"
}

# 生成表格底部边框
# Generate table bottom border
generate_table_bottom_border() {
    local col_widths=("$@")
    local line=""
    
    line+="$TABLE_BORDER_BOTTOM"
    for i in "${!col_widths[@]}"; do
        for ((j=0; j<${col_widths[i]}+2; j++)); do
            line+="$TABLE_HORIZONTAL"
        done
        if [[ $i -lt $((${#col_widths[@]} - 1)) ]]; then
            line+="$TABLE_CROSS"
        fi
    done
    line+="$TABLE_BORDER_BOTTOM_RIGHT"
    
    echo "$line"
}


# 显示中文帮助信息
# Display Chinese help information
show_help_zh() {
    display_title "Claude Code 配置切换器 (CCS) v$CCS_VERSION"
    echo -e "${BOLD}用法:${NC}"
    echo -e "  ${GREEN}ccs${NC}                                         - 显示此帮助信息"
    echo -e "  ${GREEN}ccs list|ls${NC}                                 - 显示当前配置和所有可用配置列表"  
    echo -e "  ${GREEN}ccs switch|sw <名称>${NC}                        - 切换到指定配置"
    echo -e "  ${GREEN}ccs add <名称> <密钥> <地址>${NC}                 - 添加新配置"
    echo -e "  ${GREEN}ccs delete|del|rm <名称>${NC}                    - 删除备份配置"
    echo -e "  ${GREEN}ccs rename|ren|mv <旧名称> <新名称>${NC}          - 重命名配置"
    echo -e "  ${GREEN}ccs template [配置名称]${NC}                     - 将配置设为模板（默认使用当前配置）"
    echo -e "  ${GREEN}ccs modify <配置名称> <密钥> <地址>${NC}          - 修改配置的密钥和地址（仅非激活配置）"
    echo -e "  ${GREEN}ccs update${NC}                                 - 更新脚本到最新版本"
    echo -e "  ${GREEN}ccs uninstall${NC}                              - 卸载 CCS 工具"
    echo -e "  ${GREEN}ccs version${NC}                                - 显示版本信息"
    echo -e "  ${GREEN}ccs help${NC}                                   - 显示此帮助信息"
    echo ""
    echo -e "${BOLD}示例:${NC}"
    echo -e "  ${CYAN}ccs template${NC}                          - 将当前配置设为模板"
    echo -e "  ${CYAN}ccs template work${NC}                     - 将 work 配置设为模板"
    echo -e "  ${CYAN}ccs modify work sk-new https://api.anthropic.com${NC} - 修改 work 配置"
    echo -e "  ${CYAN}ccs update${NC}                            - 检查并更新到最新版本"
    echo ""
    echo -e "${BOLD}配置文件说明:${NC}"
    local naming_convention=$(get_cached_config "naming_convention")
    local config_example=""
    local template_file=""
    if [[ "$naming_convention" == "prefix" ]]; then
        config_example="~/.claude/settings-<名称>.json"
        template_file="~/.claude/$(basename "$(get_default_file_path)")"
    else
        config_example="~/.claude/settings.json.<名称>"
        template_file="~/.claude/$(basename "$(get_default_file_path)")"
    fi
    echo -e "  ${ICON_CONFIG} Claude 配置文件地址: ${YELLOW}$config_example${NC}"
    echo -e "  ${ICON_CONFIG} CCS 工具配置文件地址: ${YELLOW}~/.claude/ccs.conf${NC}"
    echo -e "  ${ICON_CONFIG} 配置模板文件地址: ${YELLOW}$template_file${NC}"
    echo ""
    echo -e "${ICON_INFO} 名称只能包含英文字母、拼音、数字和下划线"
}

# 显示版本信息
# Display version information
show_version() {
    local lang="${1:-}"
    
    # 如果没有指定语言参数，使用用户配置的默认语言
    # If no language parameter specified, use user's default language
    if [[ -z "$lang" ]]; then
        lang=$(read_user_config "default_language")
        if [[ -z "$lang" ]]; then
            lang="zh"  # 如果读取失败，默认使用中文
        fi
    fi
    
    if [[ "$lang" == "en" ]]; then
        display_title "Claude Configuration Switcher (CCS) v$CCS_VERSION"
        echo -e "${ICON_INFO} A command-line tool for managing multiple Claude API configurations."
        echo -e "${ICON_ARROW} Easily switch between different API keys and base URLs."
        echo ""
        echo -e "${BOLD}Project:${NC}"
        echo -e "  ${ICON_CONFIG} Repository: ${CYAN}$REPOSITORY_URL${NC}"
        echo -e "  ${ICON_DOT} License: ${YELLOW}$LICENSE${NC}"
        echo -e "  ${ICON_STAR} Author: $AUTHOR"
    else
        display_title "Claude 配置切换器 (CCS) v$CCS_VERSION"
        echo -e "${ICON_INFO} 用于管理多个 Claude API 配置的命令行工具。"
        echo -e "${ICON_ARROW} 可以轻松在不同的 API 密钥和基础 URL 之间切换。"
        echo ""
        echo -e "${BOLD}项目信息:${NC}"
        echo -e "  ${ICON_CONFIG} 项目地址: ${CYAN}$REPOSITORY_URL${NC}"
        echo -e "  ${ICON_DOT} 许可证: ${YELLOW}$LICENSE${NC}"
        echo -e "  ${ICON_STAR} 作者: $AUTHOR"
    fi
}
# 显示英文帮助信息
# Display English help information
show_help_en() {
    display_title "Claude Code Configuration Switcher (CCS) v$CCS_VERSION"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${GREEN}ccs${NC}                                         - Show this help information"
    echo -e "  ${GREEN}ccs list|ls${NC}                                 - Show current configuration and list all available configurations" 
    echo -e "  ${GREEN}ccs switch|sw <name>${NC}                        - Switch to configuration <name>"
    echo -e "  ${GREEN}ccs add <name> <api_key> <base_url>${NC}         - Add new configuration"
    echo -e "  ${GREEN}ccs delete|del|rm <name>${NC}                    - Delete backup configuration"
    echo -e "  ${GREEN}ccs rename|ren|mv <old> <new>${NC}               - Rename configuration"
    echo -e "  ${GREEN}ccs template [config_name]${NC}                  - Set configuration as template (default: current config)"
    echo -e "  ${GREEN}ccs modify <config_name> <key> <url>${NC}        - Modify configuration API key and base URL (non-active only)"
    echo -e "  ${GREEN}ccs update${NC}                                 - Update script to latest version"
    echo -e "  ${GREEN}ccs uninstall${NC}                               - Uninstall CCS tool"
    echo -e "  ${GREEN}ccs version${NC}                                 - Show version information"
    echo -e "  ${GREEN}ccs help${NC}                                    - Show this help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${CYAN}ccs template${NC}                            - Set current configuration as template"
    echo -e "  ${CYAN}ccs template work${NC}                       - Set work configuration as template"
    echo -e "  ${CYAN}ccs modify work sk-new https://api.anthropic.com${NC} - Modify work configuration"
    echo -e "  ${CYAN}ccs update${NC}                            - Check for updates and update if available"
    echo ""
    echo -e "${BOLD}Configuration files:${NC}"
    local naming_convention=$(get_cached_config "naming_convention")
    local config_example=""
    local template_file=""
    if [[ "$naming_convention" == "prefix" ]]; then
        config_example="~/.claude/settings-<name>.json"
        template_file="~/.claude/$(basename "$(get_default_file_path)")"
    else
        config_example="~/.claude/settings.json.<name>"
        template_file="~/.claude/$(basename "$(get_default_file_path)")"
    fi
    echo -e "  ${ICON_CONFIG} Claude configuration files: ${YELLOW}$config_example${NC}"
    echo -e "  ${ICON_CONFIG} CCS tool configuration file: ${YELLOW}~/.claude/ccs.conf${NC}"
    echo -e "  ${ICON_CONFIG} Configuration template file: ${YELLOW}$template_file${NC}"
    echo ""
    echo -e "${ICON_INFO} Name can only contain English letters, pinyin, numbers, and underscores"
}

# 显示帮助信息
# Display help information
show_help() {
    local lang=$(get_language)
    case "$lang" in
        "en")
            show_help_en
            ;;
        "zh"|"")
            show_help_zh
            ;;
        *)
            # 如果配置了不支持的语言，默认显示中文帮助
            # If configured with unsupported language, default to Chinese help
            show_help_zh
            ;;
    esac
}

# 统一的错误处理函数
# Unified error handling function
handle_error() {
    local error_code="$1"
    local context="$2"
    local lang=$(get_language)
    
    case "$error_code" in
        "missing_config")
            show_message "$lang" \
                "Error: Configuration '$context' not found" \
                "错误：未找到配置 '$context'"
            show_message "$lang" "Available configurations:" "可用配置："
            list_configs
            return 1
            ;;
        "invalid_name")
            show_message "$lang" \
                "Error: Name can only contain English letters, numbers, and underscores" \
                "错误：名称只能包含英文字母、数字和下划线"
            return 1
            ;;
        "missing_params")
            show_message "$lang" \
                "Error: $context" \
                "错误：$context"
            return 1
            ;;
        "file_exists")
            show_message "$lang" \
                "Error: Configuration '$context' already exists" \
                "错误：配置 '$context' 已存在"
            return 1
            ;;
        "active_config")
            show_message "$lang" \
                "Error: Cannot modify/delete the currently active configuration '$context'" \
                "错误：无法修改/删除当前激活的配置 '$context'"
            return 1
            ;;
    esac
}

# 验证配置名称格式
# Validate configuration name format
validate_name() {
    local name="$1"
    # 只允许英文字母、数字、下划线
    # Only allow English letters, numbers, underscores
    if [[ ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        handle_error "invalid_name" "$name"
        return 1
    fi
    return 0
}

# 提取JSON文件中的API配置
# Extract API configuration from JSON file
extract_api_config() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # 提取ANTHROPIC_API_KEY和ANTHROPIC_BASE_URL
    # Extract ANTHROPIC_API_KEY and ANTHROPIC_BASE_URL using cut command
    local api_key=$(grep "$ANTHROPIC_API_KEY_FIELD" "$file" | cut -d'"' -f4)
    local base_url=$(grep "$ANTHROPIC_BASE_URL_FIELD" "$file" | cut -d'"' -f4)
    
    echo "${api_key}|${base_url}"
}

# 比较两个配置文件的API配置是否相同
# Compare if two configuration files have the same API configuration
compare_api_config() {
    local file1="$1"
    local file2="$2"
    
    local config1=$(extract_api_config "$file1")
    local config2=$(extract_api_config "$file2")
    
    if [[ "$config1" == "$config2" && -n "$config1" ]]; then
        return 0  # 相同
    else
        return 1  # 不同或提取失败
    fi
}

# 获取配置名称的最大长度（用于对齐显示）
# Get maximum length of configuration names for alignment
get_max_config_name_length() {
    local max_length=0
    local pattern="$(get_file_pattern)"
    for file in "$CLAUDE_DIR"/*; do
        if [[ -f "$file" && $(basename "$file") =~ $pattern ]]; then
            local default_file_path="$(get_default_file_path)"
            if [[ "$file" != "$default_file_path" ]]; then
                local name=$(extract_config_name "$file")
                local length=${#name}
                if [[ $length -gt $max_length ]]; then
                    max_length=$length
                fi
            fi
        fi
    done
    echo $max_length
}

# 格式化显示配置项（对齐）
# Format configuration item display (aligned)
format_config_display() {
    local name="$1"
    local filename="$2"
    local is_active="$3"
    local lang="$4"
    local max_length="$5"
    
    # 计算需要的空格数进行对齐
    # Calculate spaces needed for alignment
    local spaces_needed=$((max_length - ${#name}))
    local spaces=$(generate_spaces "$spaces_needed")
    
    if [[ "$is_active" == "true" ]]; then
        show_message "$lang" \
            "  ✓ $name$spaces - $filename (active)" \
            "  ✓ $name$spaces - $filename (激活)"
    else
        echo "    $name$spaces - $filename"
    fi
}

# 列出所有可用的配置文件并显示当前配置
# List all available configuration files and show current configuration
list_configs_with_current() {
    local lang=$(get_language)
    
    # 首先显示当前激活的配置信息
    # First show current active configuration info
    if [[ "$lang" == "en" ]]; then
        echo -e "${BOLD}${CYAN}${ICON_ACTIVE} Current Configuration:${NC}"
    else
        echo -e "${BOLD}${CYAN}${ICON_ACTIVE} 当前配置：${NC}"
    fi
    
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "  ${RED}${ICON_ERROR} No active configuration${NC}"
        else
            echo -e "  ${RED}${ICON_ERROR} 无激活配置${NC}"
        fi
    else
        # 通过比较API配置找到匹配的备份文件
        # Find matching backup file by comparing API configuration
        local current_found=false
        local pattern="$(get_file_pattern)"
        for file in "$CLAUDE_DIR"/*; do
            if [[ -f "$file" && $(basename "$file") =~ $pattern ]]; then
                local default_file_path="$(get_default_file_path)"
                if [[ "$file" != "$default_file_path" ]]; then
                    # 使用API配置比较
                    # Use API configuration comparison
                    if compare_api_config "$SETTINGS_FILE" "$file"; then
                        # 从文件名中提取配置名称
                        # Extract configuration name from filename
                        local name=$(extract_config_name "$file")
                        local filename=$(basename "$file")
                        echo -e "  ${GREEN}${ICON_CHECK} ${BOLD}$name${NC} ${YELLOW}($filename)${NC} ${GREEN}(激活)${NC}"
                        current_found=true
                        # 保存当前配置名称到配置文件
                        # Save current configuration name to config file
                        write_user_config "current_config" "$name"
                        break
                    fi
                fi
            fi
        done
        
        if [[ "$current_found" == false ]]; then
            if [[ "$lang" == "en" ]]; then
                echo -e "  ${YELLOW}${ICON_CHECK} ${BOLD}unknown${NC} ${YELLOW}(settings.json)${NC} ${RED}(no matching backup found)${NC}"
            else
                echo -e "  ${YELLOW}${ICON_CHECK} ${BOLD}未知${NC} ${YELLOW}(settings.json)${NC} ${RED}(未找到匹配的备份文件)${NC}"
            fi
            # 清空当前配置记录
            # Clear current configuration record
            write_user_config "current_config" ""
        fi
    fi
    
    echo ""
    if [[ "$lang" == "en" ]]; then
        echo -e "${BOLD}${BLUE}${ICON_CONFIG} Available Configurations:${NC}"
    else
        echo -e "${BOLD}${BLUE}${ICON_CONFIG} 可用配置：${NC}"
    fi
    
    # 遍历所有备份配置文件并显示详细信息
    # Iterate through all backup configuration files and show details
    local has_configs=false
    local pattern="$(get_file_pattern)"
    for file in "$CLAUDE_DIR"/*; do
        if [[ -f "$file" && $(basename "$file") =~ $pattern ]]; then
            local default_file_path="$(get_default_file_path)"
            if [[ "$file" != "$default_file_path" ]]; then
                # 从文件名中提取配置名称
                # Extract configuration name from filename
                local name=$(extract_config_name "$file")
                local filename=$(basename "$file")
                
                # 读取API配置信息
                # Read API configuration information
                local api_config=$(extract_api_config "$file")
                local api_key=$(echo "$api_config" | cut -d'|' -f1)
                local base_url=$(echo "$api_config" | cut -d'|' -f2)
                
                # 脱敏处理API信息
                # Sanitize API information
                local sanitized_key=$(sanitize_api_info "$api_key")
                
                # 检查是否为当前激活配置
                # Check if this is the current active configuration
                local status_icon=""
                local status_text=""
                local name_color=""
                
                if [[ -f "$SETTINGS_FILE" ]] && compare_api_config "$SETTINGS_FILE" "$file"; then
                    if [[ "$lang" == "en" ]]; then
                        status_text="(Active)"
                    else
                        status_text="(激活)"
                    fi
                    status_icon="${GREEN}${ICON_CHECK}${NC}"
                    name_color="${GREEN}${BOLD}"
                else
                    status_text=""
                    status_icon="${CYAN}${ICON_DOT}${NC}"
                    name_color="${BOLD}"
                fi
                
                # 显示配置信息
                # Display configuration information
                echo -e "  $status_icon ${name_color}$name${NC} ${YELLOW}($filename)${NC} ${GREEN}$status_text${NC}"
                echo -e "    ${ICON_ARROW} Base URL: ${CYAN}$base_url${NC}"
                echo -e "    ${ICON_ARROW} API Key:  ${MAGENTA}$sanitized_key${NC}"
                echo ""
                
                has_configs=true
            fi
        fi
    done
    
    if [[ "$has_configs" == false ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "  ${RED}${ICON_ERROR} No configurations found${NC}"
            echo -e "  ${ICON_INFO} Use ${GREEN}'ccs add <name> <api_key> <base_url>'${NC} to create your first configuration"
        else
            echo -e "  ${RED}${ICON_ERROR} 未找到配置${NC}"
            echo -e "  ${ICON_INFO} 使用 ${GREEN}'ccs add <名称> <密钥> <地址>'${NC} 创建您的第一个配置"
        fi
    fi
}

# 重命名配置
# Rename configuration
rename_config() {
    local old_name="$1"
    local new_name="$2"
    local lang=$(get_language)
    local old_file="$(get_config_file_path "$old_name")"
    local new_file="$(get_config_file_path "$new_name")"
    
    # 检查参数是否提供
    # Check if parameters are provided
    if [[ -z "$old_name" || -z "$new_name" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Both old and new configuration names are required"
            echo "Usage: ccs rename <old_name> <new_name>"
        else
            echo "错误：需要提供旧配置名和新配置名"
            echo "用法：ccs rename <旧名称> <新名称>"
        fi
        return 1
    fi
    
    # 验证配置名称格式
    # Validate configuration name format
    if ! validate_name "$old_name" || ! validate_name "$new_name"; then
        return 1
    fi
    
    # 检查旧配置是否存在
    # Check if old configuration exists
    if [[ ! -f "$old_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration '$old_name' not found"
            echo "Available configurations:"
        else
            echo "错误：未找到配置 '$old_name'"
            echo "可用配置："
        fi
        list_configs
        return 1
    fi
    
    # 检查新配置名是否已存在
    # Check if new configuration name already exists
    if [[ -f "$new_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration '$new_name' already exists"
        else
            echo "错误：配置 '$new_name' 已存在"
        fi
        return 1
    fi
    
    # 执行重命名
    # Perform rename
    mv "$old_file" "$new_file"
    
    # 如果重命名的是当前激活的配置，更新配置文件记录
    # If renaming the currently active configuration, update config file record
    local current_config=$(read_user_config "current_config")
    if [[ "$current_config" == "$old_name" ]]; then
        write_user_config "current_config" "$new_name"
    fi
    
    if [[ "$lang" == "en" ]]; then
        echo "Renamed configuration: $old_name -> $new_name"
    else
        echo "已重命名配置: $old_name -> $new_name"
    fi
}

# 简单列出配置（用于其他命令调用）
# Simple list configurations (for use by other commands)
list_configs() {
    local lang=$(get_language)
    show_message "$lang" "Available configurations:" "可用配置："
    
    # 遍历所有备份配置文件
    # Iterate through all backup configuration files
    local pattern="$(get_file_pattern)"
    for file in "$CLAUDE_DIR"/*; do
        if [[ -f "$file" && $(basename "$file") =~ $pattern ]]; then
            local default_file_path="$(get_default_file_path)"
            if [[ "$file" != "$default_file_path" ]]; then
                # 从文件名中提取配置名称
                # Extract configuration name from filename
                local name=$(extract_config_name "$file")
                local filename=$(basename "$file")
                echo "    $name - $filename"
            fi
        fi
    done
}

# 切换到指定的配置
# Switch to specified configuration
switch_config() {
    local name="$1"
    local lang=$(get_language)
    local backup_file="$(get_config_file_path "$name")"
    
    # 检查配置名称是否提供
    # Check if configuration name is provided
    if [[ -z "$name" ]]; then
        show_message "$lang" "Error: Configuration name is required" "错误：需要提供配置名称"
        return 1
    fi
    
    # 检查备份文件是否存在
    # Check if backup file exists
    if [[ ! -f "$backup_file" ]]; then
        show_message "$lang" \
            "Error: Configuration '$name' not found" \
            "错误：未找到配置 '$name'"
        show_message "$lang" "Available configurations:" "可用配置："
        list_configs
        return 1
    fi
    
    # 删除当前激活的配置文件（如果存在）
    # Remove current active settings if exists
    if [[ -f "$SETTINGS_FILE" ]]; then
        rm "$SETTINGS_FILE"
    fi
    
    # 将备份文件复制为激活配置
    # Copy backup file to active settings
    cp "$backup_file" "$SETTINGS_FILE"
    
    # 保存当前配置名称到配置文件
    # Save current configuration name to config file
    write_user_config "current_config" "$name"
    
    if [[ "$lang" == "en" ]]; then
        echo -e "${GREEN}${ICON_SUCCESS} Switched to configuration: ${BOLD}$name${NC}"
        echo ""
        echo -e "${YELLOW}${ICON_WARNING} Important: Please restart Claude Code for the changes to take effect.${NC}"
        echo -e "  ${ICON_ARROW} You can restart Claude Code by closing and reopening it."
        echo -e "  ${ICON_ARROW} After restarting, you can continue your previous task with: ${CYAN}claude --resume${NC}"
    else
        echo -e "${GREEN}${ICON_SUCCESS} 已切换到配置: ${BOLD}$name${NC}"
        echo ""
        echo -e "${YELLOW}${ICON_WARNING} 重要提醒：请重启 Claude Code 以使更改生效。${NC}"
        echo -e "  ${ICON_ARROW} 您可以通过关闭并重新打开 Claude Code 来重启。"
        echo -e "  ${ICON_ARROW} 重启后，您可以使用以下命令继续之前的任务: ${CYAN}claude --resume${NC}"
    fi
}

# 添加新的配置
# Add new configuration
add_config() {
    local name="$1"
    local api_key="$2"
    local base_url="$3"
    local lang=$(get_language)
    local backup_file="$(get_config_file_path "$name")"
    
    # 检查所有必需参数是否提供
    # Check if all required parameters are provided
    if [[ -z "$name" || -z "$api_key" || -z "$base_url" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: All parameters are required"
            echo "Usage: ccs add <name> <api_key> <base_url>"
        else
            echo "错误：需要提供所有参数"
            echo "用法：ccs add <名称> <密钥> <地址>"
        fi
        return 1
    fi
    
    # 验证配置名称格式
    # Validate configuration name format
    if ! validate_name "$name"; then
        return 1
    fi
    
    # 检查是否存在默认模板文件，如果不存在则创建
    # Check if default template file exists, create if not
    local default_file="$(get_default_file_path)"
    if [[ ! -f "$default_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Default template file not found, creating it automatically..."
        else
            echo "默认模板文件不存在，正在自动创建..."
        fi
        create_default_template
        if [[ "$lang" == "en" ]]; then
            echo "Default template file created: $(basename "$default_file")"
        else
            echo "默认模板文件已创建: $(basename "$default_file")"
        fi
        echo ""
    fi
    
    # 检查配置是否已存在，询问是否覆盖
    # Check if configuration already exists, ask for overwrite confirmation
    if [[ -f "$backup_file" ]]; then
        if ! confirm_action "$lang" \
            "Configuration '$name' already exists. Overwrite?" \
            "配置 '$name' 已存在。是否覆盖？"; then
            show_message "$lang" "Operation cancelled" "操作已取消"
            return 1
        fi
    fi
    
    # 创建 claude 目录（如果不存在）
    # Create claude directory if it doesn't exist
    mkdir -p "$CLAUDE_DIR"
    
    # 复制模板文件并修改 API 配置
    # Copy template file and modify API configuration
    cp "$default_file" "$backup_file"
    
    # 使用 sed 修改 API_KEY 和 BASE_URL
    # Use sed to modify API_KEY and BASE_URL
    sed -i.bak \
        -e "s|\"$ANTHROPIC_API_KEY_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_API_KEY_FIELD\": \"$api_key\"|" \
        -e "s|\"$ANTHROPIC_BASE_URL_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_BASE_URL_FIELD\": \"$base_url\"|" \
        "$backup_file"
    
    # 删除备份文件
    # Remove backup file
    rm -f "${backup_file}.bak"
    
    if [[ "$lang" == "en" ]]; then
        echo -e "${GREEN}${ICON_SUCCESS} Added configuration: ${BOLD}$name${NC}"
        echo -e "${ICON_CONFIG} File created: ${YELLOW}$backup_file${NC}"
    else
        echo -e "${GREEN}${ICON_SUCCESS} 已添加配置: ${BOLD}$name${NC}"
        echo -e "${ICON_CONFIG} 文件已创建: ${YELLOW}$backup_file${NC}"
    fi
}

# 删除备份配置文件
# Delete backup configuration file
delete_config() {
    local name="$1"
    local lang=$(get_language)
    local backup_file="$(get_config_file_path "$name")"
    
    # 检查配置名称是否提供
    # Check if configuration name is provided
    if [[ -z "$name" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration name is required"
            echo "Usage: ccs delete <name>"
        else
            echo "错误：需要提供配置名称"
            echo "用法：ccs delete <名称>"
        fi
        return 1
    fi
    
    # 验证配置名称格式
    # Validate configuration name format
    if ! validate_name "$name"; then
        return 1
    fi
    
    # 检查备份文件是否存在
    # Check if backup file exists
    if [[ ! -f "$backup_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration '$name' not found"
            echo "Available configurations:"
        else
            echo "错误：未找到配置 '$name'"
            echo "可用配置："
        fi
        list_configs
        return 1
    fi
    
    # 检查是否为当前激活的配置，如果是则禁止删除
    # Check if it's the currently active configuration, prevent deletion if so
    if [[ -f "$SETTINGS_FILE" ]] && compare_api_config "$SETTINGS_FILE" "$backup_file"; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Error: Cannot delete the currently active configuration '${BOLD}$name${NC}${RED}'${NC}"
            echo -e "${ICON_INFO} Please switch to another configuration first using: ${GREEN}ccs switch <other_config>${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 错误：无法删除当前激活的配置 '${BOLD}$name${NC}${RED}'${NC}"
            echo -e "${ICON_INFO} 请先切换到其他配置，使用：${GREEN}ccs switch <其他配置>${NC}"
        fi
        return 1
    fi
    
    # 确认删除操作
    # Confirm deletion operation
    if [[ "$lang" == "en" ]]; then
        read -p "Are you sure you want to delete configuration '$name'? (y/N): " -n 1 -r
    else
        read -p "确定要删除配置 '$name' 吗？(y/N): " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Operation cancelled"
        else
            echo "操作已取消"
        fi
        return 1
    fi
    
    # 删除备份文件
    # Delete backup file
    rm "$backup_file"
    if [[ "$lang" == "en" ]]; then
        echo -e "${GREEN}${ICON_SUCCESS} Deleted configuration: ${BOLD}$name${NC}"
    else
        echo -e "${GREEN}${ICON_SUCCESS} 已删除配置: ${BOLD}$name${NC}"
    fi
}

# 将当前配置设置为模板配置
# Set current configuration as template
set_template_config() {
    local config_name="${1:-}"
    local lang=$(get_language)
    local source_file=""
    
    # 确定源文件
    # Determine source file
    if [[ -z "$config_name" ]]; then
        # 使用当前激活的配置文件
        # Use current active configuration file
        if [[ ! -f "$SETTINGS_FILE" ]]; then
            if [[ "$lang" == "en" ]]; then
                echo "Error: No active configuration found"
                echo "Please switch to a configuration first using 'ccs switch <name>'"
            else
                echo "错误：未找到激活的配置"
                echo "请先使用 'ccs switch <名称>' 切换到一个配置"
            fi
            return 1
        fi
        source_file="$SETTINGS_FILE"
        if [[ "$lang" == "en" ]]; then
            echo "Using current active configuration as template source"
        else
            echo "使用当前激活的配置作为模板源"
        fi
    else
        # 使用指定的配置文件
        # Use specified configuration file
        local backup_file="$(get_config_file_path "$config_name")"
        if [[ ! -f "$backup_file" ]]; then
            if [[ "$lang" == "en" ]]; then
                echo "Error: Configuration '$config_name' not found"
                echo "Available configurations:"
            else
                echo "错误：未找到配置 '$config_name'"
                echo "可用配置："
            fi
            list_configs "$lang"
            return 1
        fi
        source_file="$backup_file"
        if [[ "$lang" == "en" ]]; then
            echo "Using configuration '$config_name' as template source"
        else
            echo "使用配置 '$config_name' 作为模板源"
        fi
    fi
    
    # 确认操作
    # Confirm operation
    if [[ "$lang" == "en" ]]; then
        echo "This will create a new template file from the specified configuration."
        if [[ -f "$DEFAULT_FILE" ]]; then
            echo "Warning: This will overwrite the existing template file."
        fi
        read -p "Continue? (y/N): " -n 1 -r
    else
        echo "这将从指定的配置创建新的模板文件。"
        if [[ -f "$DEFAULT_FILE" ]]; then
            echo "警告：这将覆盖现有的模板文件。"
        fi
        read -p "继续？(y/N): " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Operation cancelled"
        else
            echo "操作已取消"
        fi
        return 1
    fi
    
    # 创建 claude 目录（如果不存在）
    # Create claude directory if it doesn't exist
    mkdir -p "$CLAUDE_DIR"
    
    # 复制配置为模板文件并替换敏感信息
    # Copy configuration as template file and replace sensitive information
    local default_file_path="$(get_default_file_path)"
    cp "$source_file" "$default_file_path"
    
    # 使用 sed 将 API_KEY 和 BASE_URL 替换为占位符
    # Use sed to replace API_KEY and BASE_URL with placeholders
    sed -i.bak \
        -e "s|\"$ANTHROPIC_API_KEY_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_API_KEY_FIELD\": \"$API_KEY_PLACEHOLDER\"|" \
        -e "s|\"$ANTHROPIC_BASE_URL_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_BASE_URL_FIELD\": \"$BASE_URL_PLACEHOLDER\"|" \
        "$default_file_path"
    
    # 删除备份文件
    # Remove backup file
    rm -f "${default_file_path}.bak"
    
    if [[ "$lang" == "en" ]]; then
        echo "Template file created successfully: $default_file_path"
        echo "API credentials have been replaced with placeholders."
    else
        echo "模板文件创建成功: $default_file_path"
        echo "API 凭证已替换为占位符。"
    fi
}





# 修改配置的API密钥和地址
# Modify configuration API key and base URL
modify_config() {
    local config_name="$1"
    local api_key="$2"
    local base_url="$3"
    local lang=$(get_language)
    local target_file=""
    
    # 检查配置名称是否提供
    # Check if configuration name is provided
    if [[ -z "$config_name" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration name is required"
            echo "Usage: ccs modify <config_name> <api_key> <base_url>"
            echo "       ccs modify <config_name> <api_key> \"\"      # Only update API key"
            echo "       ccs modify <config_name> \"\" <base_url>      # Only update base URL"
            echo ""
            echo "Note: Cannot modify currently active configuration because Claude Code"
            echo "      requires restart to read configuration changes. Please modify"
            echo "      a non-active configuration and then switch to it."
        else
            echo "错误：需要提供配置名称"
            echo "用法：ccs modify <配置名称> <密钥> <地址>"
            echo "     ccs modify <配置名称> <密钥> \"\"      # 只更新API密钥"
            echo "     ccs modify <配置名称> \"\" <地址>      # 只更新基础URL"
            echo ""
            echo "注意：无法修改当前激活的配置，因为 Claude Code 需要重启才能"
            echo "      读取配置更改。请修改非激活状态的配置，然后切换到该配置。"
        fi
        return 1
    fi
    
    # 修改指定的配置文件
    # Modify specified configuration file
    local backup_file="$(get_config_file_path "$config_name")"
    if [[ ! -f "$backup_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: Configuration '$config_name' not found"
            echo "Available configurations:"
        else
            echo "错误：未找到配置 '$config_name'"
            echo "可用配置："
        fi
        list_configs
        return 1
    fi
    
    # 检查是否为当前激活的配置，如果是则禁止修改
    # Check if it's the currently active configuration, prevent modification if so
    if [[ -f "$SETTINGS_FILE" ]] && compare_api_config "$SETTINGS_FILE" "$backup_file"; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Error: Cannot modify the currently active configuration '${BOLD}$config_name${NC}${RED}'${NC}"
            echo -e "${ICON_INFO} Claude Code requires restart to read configuration changes."
            echo -e "${ICON_INFO} Please switch to another configuration first, then modify this one."
        else
            echo -e "${RED}${ICON_ERROR} 错误：无法修改当前激活的配置 '${BOLD}$config_name${NC}${RED}'${NC}"
            echo -e "${ICON_INFO} Claude Code 需要重启才能读取配置更改。"
            echo -e "${ICON_INFO} 请先切换到其他配置，然后再修改此配置。"
        fi
        return 1
    fi
    
    target_file="$backup_file"
    if [[ "$lang" == "en" ]]; then
        echo "Modifying configuration: $config_name"
    else
        echo "修改配置: $config_name"
    fi
    
    # 检查参数
    # Check parameters
    if [[ -z "$api_key" && -z "$base_url" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Error: At least one of API key or base URL must be provided"
            echo "Usage: ccs modify <config_name> <api_key> <base_url>"
            echo "       ccs modify <config_name> <api_key> \"\"      # Only update API key"
            echo "       ccs modify <config_name> \"\" <base_url>      # Only update base URL"
            echo "Examples:"
            echo "  ccs modify work sk-ant-new https://api.anthropic.com # Modify 'work' config"
        else
            echo "错误：必须提供API密钥或基础URL中的至少一个"
            echo "用法：ccs modify <配置名称> <密钥> <地址>"
            echo "     ccs modify <配置名称> <密钥> \"\"      # 只更新API密钥"
            echo "     ccs modify <配置名称> \"\" <地址>      # 只更新基础URL"
            echo "示例："
            echo "  ccs modify work sk-ant-new https://api.anthropic.com # 修改 'work' 配置"
        fi
        return 1
    fi
    
    # 显示当前配置信息
    # Show current configuration info
    show_message "$lang" "Current configuration in file:" "文件中的当前配置："
    
    local current_config=$(extract_api_config "$target_file")
    local current_api_key=$(echo "$current_config" | cut -d'|' -f1)
    local current_base_url=$(echo "$current_config" | cut -d'|' -f2)
    
    echo "  API Key: $current_api_key"
    echo "  Base URL: $current_base_url"
    echo ""
    
    # 确认操作
    # Confirm operation
    show_message "$lang" "Changes to apply:" "要应用的更改："
    [[ -n "$api_key" ]] && echo "  New API Key: $api_key"
    [[ -n "$base_url" ]] && echo "  New Base URL: $base_url"
    echo ""
    
    if ! confirm_action "$lang" "Apply these changes?" "应用这些更改？"; then
        show_message "$lang" "Operation cancelled" "操作已取消"
        return 1
    fi
    
    # 执行修改
    # Execute modifications
    local sed_commands=()
    
    if [[ -n "$api_key" ]]; then
        sed_commands+=(-e "s|\"$ANTHROPIC_API_KEY_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_API_KEY_FIELD\": \"$api_key\"|")
    fi
    
    if [[ -n "$base_url" ]]; then
        sed_commands+=(-e "s|\"$ANTHROPIC_BASE_URL_FIELD\": \"[^\"]*\"|\"$ANTHROPIC_BASE_URL_FIELD\": \"$base_url\"|")
    fi
    
    # 应用更改（不创建备份文件）
    # Apply changes (without creating backup files)
    sed -i.tmp "${sed_commands[@]}" "$target_file"
    rm -f "${target_file}.tmp"
    
    if [[ "$lang" == "en" ]]; then
        echo "Configuration updated successfully!"
    else
        echo "配置更新成功！"
    fi
}

# 检查是否有可用更新
# Check if updates are available
check_for_updates() {
    local lang="$1"
    local silent="${2:-false}"  # 静默模式，只返回状态
    local temp_file_var="$3"    # 可选，用于返回临时文件路径
    
    if [[ "$silent" != "true" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${BOLD}${BLUE}${ICON_INFO} Checking updates...${NC}"
        else
            echo -e "${BOLD}${BLUE}${ICON_INFO} 检查更新...${NC}"
        fi
    fi
    
    local current_version="$CCS_VERSION"
    local latest_version
    local need_download=false
    
    # 第一阶段：快速版本检查（从GitHub API）
    latest_version=$(get_latest_version_info "$lang")
    
    if [[ "$latest_version" == "unknown" ]]; then
        # GitHub API不可用，需要下载文件检查
        need_download=true
        if [[ "$silent" != "true" ]]; then
            if [[ "$lang" == "en" ]]; then
                echo -e "${YELLOW}${ICON_WARNING} API unavailable, downloading...${NC}"
            else
                echo -e "${YELLOW}${ICON_WARNING} API 不可用，正在下载...${NC}"
            fi
        fi
    else
        # 先进行快速比较
        compare_versions "$current_version" "$latest_version"
        local quick_comparison_result=$?
        
        if [[ $quick_comparison_result -eq 0 ]]; then
            # 版本相同，无需更新，也无需下载
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${GREEN}${ICON_SUCCESS} Already latest version${NC}"
                    echo -e "  ${ICON_ARROW} Version: ${GREEN}v$current_version${NC}"
                else
                    echo -e "${GREEN}${ICON_SUCCESS} 已是最新版本${NC}"
                    echo -e "  ${ICON_ARROW} 版本: ${GREEN}v$current_version${NC}"
                fi
            fi
            return 3  # 已是最新
        else
            # 版本不同，需要下载文件进行精确检查和准备更新
            need_download=true
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${BLUE}${ICON_INFO} Version differs, downloading...${NC}"
                else
                    echo -e "${BLUE}${ICON_INFO} 版本不同，正在下载...${NC}"
                fi
            fi
        fi
    fi
    
    # 第二阶段：下载文件进行精确检查（仅在需要时）
    if [[ "$need_download" == "true" ]]; then
        local temp_file
        local downloaded_version
        downloaded_version=$(get_latest_version "$lang" "temp_file")
        local get_version_result=$?
        
        if [[ $get_version_result -ne 0 ]]; then
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${RED}${ICON_ERROR} Update check failed${NC}"
                else
                    echo -e "${RED}${ICON_ERROR} 检查更新失败${NC}"
                fi
            fi
            return 1
        fi
        
        # 使用从下载文件中提取的版本号
        latest_version="$downloaded_version"
        
        # 通过变量名返回临时文件路径
        if [[ -n "$temp_file_var" && -n "$temp_file" ]]; then
            eval "$temp_file_var='$temp_file'"
        fi
        
        # 重新比较版本（使用下载文件中的版本号）
        compare_versions "$current_version" "$latest_version"
        local comparison_result=$?
        
        if [[ $comparison_result -eq 2 ]]; then
            # 当前版本 < 最新版本，有更新
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${GREEN}${ICON_SUCCESS} Update available!${NC}"
                    echo -e "  ${ICON_ARROW} Current: ${YELLOW}v$current_version${NC}"
                    echo -e "  ${ICON_ARROW} Latest:  ${GREEN}v$latest_version${NC}"
                else
                    echo -e "${GREEN}${ICON_SUCCESS} 发现可用更新！${NC}"
                    echo -e "  ${ICON_ARROW} 当前: ${YELLOW}v$current_version${NC}"
                    echo -e "  ${ICON_ARROW} 最新: ${GREEN}v$latest_version${NC}"
                fi
            fi
            return 0  # 有更新
        elif [[ $comparison_result -eq 1 ]]; then
            # 当前版本 > 最新版本，开发版本
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${YELLOW}${ICON_WARNING} Running development version${NC}"
                    echo -e "  ${ICON_ARROW} Current: ${YELLOW}v$current_version${NC}"
                    echo -e "  ${ICON_ARROW} Stable:  ${GREEN}v$latest_version${NC}"
                else
                    echo -e "${YELLOW}${ICON_WARNING} 运行开发版本${NC}"
                    echo -e "  ${ICON_ARROW} 当前: ${YELLOW}v$current_version${NC}"
                    echo -e "  ${ICON_ARROW} 稳定: ${GREEN}v$latest_version${NC}"
                fi
            fi
            return 2  # 开发版本
        else
            # 当前版本 == 最新版本，已是最新
            if [[ "$silent" != "true" ]]; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${GREEN}${ICON_SUCCESS} Already latest version${NC}"
                    echo -e "  ${ICON_ARROW} Version: ${GREEN}v$current_version${NC}"
                else
                    echo -e "${GREEN}${ICON_SUCCESS} 已是最新版本${NC}"
                    echo -e "  ${ICON_ARROW} 版本: ${GREEN}v$current_version${NC}"
                fi
            fi
            # 如果已是最新版本，清理临时文件
            if [[ -n "$temp_file" && -f "$temp_file" ]]; then
                rm -f "$temp_file"
                if [[ -n "$temp_file_var" ]]; then
                    eval "$temp_file_var=''"
                fi
            fi
            return 3  # 已是最新
        fi
    fi
}

# 自动更新脚本（简化版）
# Auto update script (simplified)
update_script() {
    local lang="$1"
    
    display_title "CCS 自动更新 / CCS Auto Update"
    echo ""
    
    # 检查更新
    if [[ "$lang" == "en" ]]; then
        echo -e "${BOLD}${BLUE}${ICON_INFO} Checking for updates...${NC}"
    else
        echo -e "${BOLD}${BLUE}${ICON_INFO} 检查更新...${NC}"
    fi
    
    local current_version="$CCS_VERSION"
    local remote_version
    
    # 从 CDN 获取远程版本
    remote_version=$(get_remote_version)
    
    if [[ $? -ne 0 || -z "$remote_version" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Failed to check remote version${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 检查远程版本失败${NC}"
        fi
        return 1
    fi
    
    # 比较版本
    compare_versions "$current_version" "$remote_version"
    local comparison_result=$?
    
    if [[ $comparison_result -eq 0 ]]; then
        # 版本相同，已是最新
        if [[ "$lang" == "en" ]]; then
            echo -e "${GREEN}${ICON_SUCCESS} Already up to date!${NC}"
            echo -e "  ${ICON_ARROW} Current version: ${GREEN}v$current_version${NC}"
        else
            echo -e "${GREEN}${ICON_SUCCESS} 已是最新版本！${NC}"
            echo -e "  ${ICON_ARROW} 当前版本: ${GREEN}v$current_version${NC}"
        fi
        return 0
    elif [[ $comparison_result -eq 1 ]]; then
        # 当前版本 > 远程版本，开发版本
        if [[ "$lang" == "en" ]]; then
            echo -e "${YELLOW}${ICON_WARNING} Running development version${NC}"
            echo -e "  ${ICON_ARROW} Current: ${YELLOW}v$current_version${NC}"
            echo -e "  ${ICON_ARROW} Stable:  ${GREEN}v$remote_version${NC}"
            echo ""
            echo -e "${ICON_INFO} You can downgrade to stable version if needed."
        else
            echo -e "${YELLOW}${ICON_WARNING} 运行开发版本${NC}"
            echo -e "  ${ICON_ARROW} 当前: ${YELLOW}v$current_version${NC}"
            echo -e "  ${ICON_ARROW} 稳定: ${GREEN}v$remote_version${NC}"
            echo ""
            echo -e "${ICON_INFO} 如需要，您可以降级到稳定版本。"
        fi
    else
        # 当前版本 < 远程版本，有更新
        if [[ "$lang" == "en" ]]; then
            echo -e "${GREEN}${ICON_SUCCESS} Update available!${NC}"
            echo -e "  ${ICON_ARROW} Current: ${YELLOW}v$current_version${NC}"
            echo -e "  ${ICON_ARROW} Latest:  ${GREEN}v$remote_version${NC}"
        else
            echo -e "${GREEN}${ICON_SUCCESS} 发现可用更新！${NC}"
            echo -e "  ${ICON_ARROW} 当前: ${YELLOW}v$current_version${NC}"
            echo -e "  ${ICON_ARROW} 最新: ${GREEN}v$remote_version${NC}"
        fi
    fi
    
    echo ""
    # 询问用户是否更新
    if ! confirm_update "$lang" \
        "Do you want to update now?" \
        "是否现在更新？"; then
        show_message "$lang" "Update cancelled" "更新已取消"
        return 0
    fi
    
    # 用户确认后，下载更新文件
    if [[ "$lang" == "en" ]]; then
        echo -e "${BLUE}${ICON_INFO} Downloading update...${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} 正在下载更新...${NC}"
    fi
    
    local temp_file
    temp_file=$(download_remote_file)
    if [[ $? -ne 0 || -z "$temp_file" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Download failed${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 下载失败${NC}"
        fi
        return 1
    fi
    
    # 获取脚本路径
    local script_path=$(get_script_path)
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Script not found${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 脚本未找到${NC}"
        fi
        rm -f "$temp_file"
        return 1
    fi
    
    # 检查是否需要sudo权限
    local need_sudo=false
    if [[ ! -w "$script_path" ]]; then
        need_sudo=true
        if [[ "$lang" == "en" ]]; then
            echo -e "${ICON_INFO} Admin privileges required"
        else
            echo -e "${ICON_INFO} 需要管理员权限"
        fi
    fi
    
    # 备份当前脚本
    if [[ "$lang" == "en" ]]; then
        echo "Creating backup..."
    else
        echo "正在备份..."
    fi
    
    local backup_path="${script_path}${SCRIPT_BACKUP_SUFFIX}"
    if ! cp "$script_path" "$backup_path" 2>/dev/null; then
        if [[ "$need_sudo" == "true" ]]; then
            if ! sudo cp "$script_path" "$backup_path"; then
                if [[ "$lang" == "en" ]]; then
                    echo -e "${RED}${ICON_ERROR} Backup failed${NC}"
                else
                    echo -e "${RED}${ICON_ERROR} 备份失败${NC}"
                fi
                rm -f "$temp_file"
                return 1
            fi
        else
            if [[ "$lang" == "en" ]]; then
                echo -e "${RED}${ICON_ERROR} Backup failed${NC}"
            else
                echo -e "${RED}${ICON_ERROR} 备份失败${NC}"
            fi
            rm -f "$temp_file"
            return 1
        fi
    fi
    
    if [[ "$lang" == "en" ]]; then
        echo -e "${GREEN}Backup created: $backup_path${NC}"
        echo ""
        echo "Installing update..."
    else
        echo -e "${GREEN}已备份: $backup_path${NC}"
        echo ""
        echo "正在安装更新..."
    fi
    
    # 使用预下载的临时文件进行更新
    if [[ "$need_sudo" == "true" ]]; then
        # 需要sudo权限
        if sudo cp "$temp_file" "$script_path" && sudo chmod +x "$script_path"; then
            if [[ "$lang" == "en" ]]; then
                echo -e "${GREEN}${ICON_SUCCESS} Update completed successfully!${NC}"
                echo -e "  ${ICON_ARROW} Backup: ${YELLOW}$backup_path${NC}"
                echo ""
                echo -e "${ICON_INFO} Run ${GREEN}'ccs version'${NC} to verify"
            else
                echo -e "${GREEN}${ICON_SUCCESS} 更新完成！${NC}"
                echo -e "  ${ICON_ARROW} 备份: ${YELLOW}$backup_path${NC}"
                echo ""
                echo -e "${ICON_INFO} 运行 ${GREEN}'ccs version'${NC} 验证版本"
            fi
            rm -f "$temp_file"
            return 0
        else
            if [[ "$lang" == "en" ]]; then
                echo -e "${RED}${ICON_ERROR} Update failed${NC}"
                echo -e "${ICON_INFO} Backup available at: $backup_path"
            else
                echo -e "${RED}${ICON_ERROR} 更新失败${NC}"
                echo -e "${ICON_INFO} 备份文件位于: $backup_path"
            fi
            rm -f "$temp_file"
            return 1
        fi
    else
        # 不需要sudo权限
        if cp "$temp_file" "$script_path" && chmod +x "$script_path"; then
            if [[ "$lang" == "en" ]]; then
                echo -e "${GREEN}${ICON_SUCCESS} Update completed successfully!${NC}"
                echo -e "  ${ICON_ARROW} Backup saved at: ${YELLOW}$backup_path${NC}"
                echo ""
                echo -e "${ICON_INFO} Run ${GREEN}'ccs version'${NC} to verify the new version"
            else
                echo -e "${GREEN}${ICON_SUCCESS} 更新完成！${NC}"
                echo -e "  ${ICON_ARROW} 备份保存在: ${YELLOW}$backup_path${NC}"
                echo ""
                echo -e "${ICON_INFO} 运行 ${GREEN}'ccs version'${NC} 验证新版本"
            fi
            rm -f "$temp_file"
            return 0
        else
            if [[ "$lang" == "en" ]]; then
                echo -e "${RED}${ICON_ERROR} Update failed${NC}"
                echo -e "${ICON_INFO} Backup available at: $backup_path"
            else
                echo -e "${RED}${ICON_ERROR} 更新失败${NC}"
                echo -e "${ICON_INFO} 备份文件位于: $backup_path"
            fi
            rm -f "$temp_file"
            return 1
        fi
    fi
}

# 回滚到备份版本
# Rollback to backup version
rollback_script() {
    local lang="$1"
    
    # 获取脚本路径
    # Get script path
    local script_path=$(get_script_path)
    if [[ -z "$script_path" || ! -f "$script_path" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Cannot locate current script file${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 无法定位当前脚本文件${NC}"
        fi
        return 1
    fi
    
    local backup_path="${script_path}${SCRIPT_BACKUP_SUFFIX}"
    
    # 检查备份文件是否存在
    # Check if backup file exists
    if [[ ! -f "$backup_path" ]]; then
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} No backup file found${NC}"
            echo -e "${ICON_INFO} Expected backup location: $backup_path"
        else
            echo -e "${RED}${ICON_ERROR} 未找到备份文件${NC}"
            echo -e "${ICON_INFO} 预期备份位置: $backup_path"
        fi
        return 1
    fi
    
    # 用户确认
    # User confirmation
    if [[ "$lang" == "en" ]]; then
        echo -e "${YELLOW}${ICON_WARNING} This will restore the script to its previous version${NC}"
        echo -e "${ICON_INFO} Current script: $script_path"
        echo -e "${ICON_INFO} Backup file: $backup_path"
        echo ""
    else
        echo -e "${YELLOW}${ICON_WARNING} 这将恢复脚本到之前的版本${NC}"
        echo -e "${ICON_INFO} 当前脚本: $script_path"
        echo -e "${ICON_INFO} 备份文件: $backup_path"
        echo ""
    fi
    
    if ! confirm_action "$lang" \
        "Do you want to continue with the rollback?" \
        "是否继续回滚操作？"; then
        show_message "$lang" "Rollback cancelled" "回滚已取消"
        return 0
    fi
    
    # 执行回滚
    # Perform rollback
    if cp "$backup_path" "$script_path"; then
        chmod +x "$script_path"
        if [[ "$lang" == "en" ]]; then
            echo -e "${GREEN}${ICON_SUCCESS} Rollback completed successfully${NC}"
            echo -e "${ICON_INFO} Script has been restored to the previous version"
        else
            echo -e "${GREEN}${ICON_SUCCESS} 回滚完成${NC}"
            echo -e "${ICON_INFO} 脚本已恢复到之前的版本"
        fi
        return 0
    else
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Rollback failed${NC}"
        else
            echo -e "${RED}${ICON_ERROR} 回滚失败${NC}"
        fi
        return 1
    fi
}

# 卸载 CCS 工具
# Uninstall CCS tool
uninstall_ccs() {
    local lang=$(get_language)
    
    # 扫描要删除的文件
    # Scan files to be removed
    local backup_files=()
    local has_config_file=false
    local has_template_file=false
    
    # 查找配置备份文件
    # Find configuration backup files
    local pattern="$(get_file_pattern)"
    for file in "$CLAUDE_DIR"/*; do
        if [[ -f "$file" && $(basename "$file") =~ $pattern ]]; then
            local default_file_path="$(get_default_file_path)"
            if [[ "$file" == "$default_file_path" ]]; then
                has_template_file=true
            else
                backup_files+=("$file")
            fi
        fi
    done
    
    # 检查 CCS 配置文件
    # Check CCS configuration file
    if [[ -f "$CCS_CONFIG_FILE" ]]; then
        has_config_file=true
    fi
    
    # 显示将要删除的文件
    # Show files to be removed
    if [[ "$lang" == "en" ]]; then
        echo "CCS Uninstall"
        echo "============="
        echo ""
        echo "Files found for removal:"
        echo ""
        
        # 显示配置备份文件
        # Show configuration backup files
        if [[ ${#backup_files[@]} -gt 0 ]]; then
            echo "Configuration backup files:"
            for file in "${backup_files[@]}"; do
                local name=$(extract_config_name "$file")
                echo "  - $(basename "$file") (config: $name)"
            done
            echo ""
        else
            echo "Configuration backup files: None found"
            echo ""
        fi
        
        # 显示模板文件
        # Show template file
        if [[ "$has_template_file" == true ]]; then
            echo "Template file:"
            echo "  - $(basename "$(get_default_file_path)")"
            echo ""
        else
            echo "Template file: None found"
            echo ""
        fi
        
        # 显示 CCS 配置文件
        # Show CCS configuration file
        if [[ "$has_config_file" == true ]]; then
            echo "CCS configuration file:"
            echo "  - ccs.conf"
            echo ""
        else
            echo "CCS configuration file: None found"
            echo ""
        fi
        
        echo "Note: The current active configuration (~/.claude/settings.json) will be preserved."
        echo "Note: The ~/.claude/ directory will be preserved."
        echo ""
    else
        echo "CCS 卸载"
        echo "========"
        echo ""
        echo "发现以下文件可以删除："
        echo ""
        
        # 显示配置备份文件
        # Show configuration backup files
        if [[ ${#backup_files[@]} -gt 0 ]]; then
            echo "配置备份文件："
            for file in "${backup_files[@]}"; do
                local name=$(extract_config_name "$file")
                echo "  - $(basename "$file") (配置: $name)"
            done
            echo ""
        else
            echo "配置备份文件：未找到"
            echo ""
        fi
        
        # 显示模板文件
        # Show template file
        if [[ "$has_template_file" == true ]]; then
            echo "模板文件："
            echo "  - $(basename "$(get_default_file_path)")"
            echo ""
        else
            echo "模板文件：未找到"
            echo ""
        fi
        
        # 显示 CCS 配置文件
        # Show CCS configuration file
        if [[ "$has_config_file" == true ]]; then
            echo "CCS 配置文件："
            echo "  - ccs.conf"
            echo ""
        else
            echo "CCS 配置文件：未找到"
            echo ""
        fi
        
        echo "注意：当前激活的配置文件 (~/.claude/settings.json) 将被保留。"
        echo "注意：~/.claude/ 目录将被保留。"
        echo ""
    fi
    
    # 检查是否有文件需要删除
    # Check if there are files to remove
    if [[ ${#backup_files[@]} -eq 0 && "$has_template_file" == false && "$has_config_file" == false ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "No CCS files found to remove. CCS may already be uninstalled."
        else
            echo "未找到需要删除的 CCS 文件。CCS 可能已经被卸载。"
        fi
        return 0
    fi
    
    # 用户选择删除选项
    # User selection for deletion options
    local delete_backups=false
    local delete_template=false
    local delete_config=false
    local selection_made=false
    
    # 询问是否删除配置备份文件
    # Ask about deleting configuration backup files
    if [[ ${#backup_files[@]} -gt 0 ]]; then
        if [[ "$lang" == "en" ]]; then
            read -p "Delete configuration backup files? (y/N): " -n 1 -r
        else
            read -p "删除配置备份文件？(y/N): " -n 1 -r
        fi
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_backups=true
            selection_made=true
        fi
    fi
    
    # 询问是否删除模板文件
    # Ask about deleting template file
    if [[ "$has_template_file" == true ]]; then
        if [[ "$lang" == "en" ]]; then
            read -p "Delete template file ($(basename "$(get_default_file_path)"))? (y/N): " -n 1 -r
        else
            read -p "删除模板文件 ($(basename "$(get_default_file_path)"))？(y/N): " -n 1 -r
        fi
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_template=true
            selection_made=true
        fi
    fi
    
    # 询问是否删除 CCS 配置文件
    # Ask about deleting CCS configuration file
    if [[ "$has_config_file" == true ]]; then
        if [[ "$lang" == "en" ]]; then
            read -p "Delete CCS configuration file (ccs.conf)? (y/N): " -n 1 -r
        else
            read -p "删除 CCS 配置文件 (ccs.conf)？(y/N): " -n 1 -r
        fi
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_config=true
            selection_made=true
        fi
    fi
    
    # 检查是否有任何操作需要执行
    # Check if any operations need to be performed
    if [[ "$selection_made" == false ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "No files selected for deletion. Uninstall cancelled."
        else
            echo "未选择删除任何文件。卸载已取消。"
        fi
        return 0
    fi
    
    # 最终确认
    # Final confirmation
    if [[ "$lang" == "en" ]]; then
        echo ""
        echo "Final confirmation - The following will be deleted:"
        [[ "$delete_backups" == true ]] && echo "  ✓ Configuration backup files (${#backup_files[@]} files)"
        [[ "$delete_template" == true ]] && echo "  ✓ Template file ($(basename "$(get_default_file_path)"))"
        [[ "$delete_config" == true ]] && echo "  ✓ CCS configuration file (ccs.conf)"
        echo ""
        read -p "Proceed with deletion? (y/N): " -n 1 -r
    else
        echo ""
        echo "最终确认 - 以下文件将被删除："
        [[ "$delete_backups" == true ]] && echo "  ✓ 配置备份文件 (${#backup_files[@]} 个文件)"
        [[ "$delete_template" == true ]] && echo "  ✓ 模板文件 ($(basename "$(get_default_file_path)"))"
        [[ "$delete_config" == true ]] && echo "  ✓ CCS 配置文件 (ccs.conf)"
        echo ""
        read -p "继续删除？(y/N): " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$lang" == "en" ]]; then
            echo "Uninstall cancelled"
        else
            echo "卸载已取消"
        fi
        return 1
    fi
    
    # 询问是否删除脚本文件
    # Ask about deleting script files
    local delete_script=false
    if [[ "$lang" == "en" ]]; then
        echo ""
        echo "Do you also want to delete the CCS script from your system?"
        echo "This will remove:"
        echo "  - /usr/local/bin/ccs (if installed system-wide)"
        echo "  - ~/bin/ccs (if installed in user directory)"
        echo ""
        read -p "Delete CCS script from system? (y/N): " -n 1 -r
    else
        echo ""
        echo "是否也要从系统中删除 CCS 脚本？"
        echo "这将删除："
        echo "  - /usr/local/bin/ccs (如果系统级安装)"
        echo "  - ~/bin/ccs (如果用户目录安装)"
        echo ""
        read -p "从系统中删除 CCS 脚本？(y/N): " -n 1 -r
    fi
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        delete_script=true
    fi
    
    # 删除文件
    # Remove files
    local removed_files=()
    
    # 删除配置备份文件（根据用户选择）
    # Remove configuration backup files (based on user selection)
    if [[ "$delete_backups" == true ]]; then
        for file in "${backup_files[@]}"; do
            if [[ -f "$file" ]]; then
                rm -f "$file"
                removed_files+=("$(basename "$file")")
            fi
        done
    fi
    
    # 删除模板文件（根据用户选择）
    # Remove template file (based on user selection)
    local default_file_path="$(get_default_file_path)"
    if [[ "$delete_template" == true && -f "$default_file_path" ]]; then
        rm -f "$default_file_path"
        removed_files+=("$(basename "$default_file_path")")
    fi
    
    # 删除 CCS 配置文件（根据用户选择）
    # Remove CCS configuration file (based on user selection)
    if [[ "$delete_config" == true && -f "$CCS_CONFIG_FILE" ]]; then
        rm -f "$CCS_CONFIG_FILE"
        removed_files+=("ccs.conf")
    fi
    
    # 删除脚本文件（根据用户选择）
    # Remove script files (based on user selection)
    if [[ "$delete_script" == true ]]; then
        local script_removed=false
        
        # 尝试删除系统安装的脚本
        # Try to remove system-wide installed script
        if [[ -f "/usr/local/bin/ccs" ]]; then
            if sudo rm -f "/usr/local/bin/ccs" 2>/dev/null; then
                removed_files+=("System script: /usr/local/bin/ccs")
                script_removed=true
            fi
        fi
        
        # 尝试删除用户目录安装的脚本
        # Try to remove user directory installed script
        if [[ -f "$HOME/bin/ccs" ]]; then
            if rm -f "$HOME/bin/ccs" 2>/dev/null; then
                removed_files+=("User script: ~/bin/ccs")
                script_removed=true
            fi
        fi
        
        if [[ "$script_removed" == false ]]; then
            if [[ "$lang" == "en" ]]; then
                echo "Warning: No CCS script found in common installation locations."
                echo "You may need to manually remove the script if installed elsewhere."
            else
                echo "警告：未在常见安装位置找到 CCS 脚本。"
                echo "如果安装在其他位置，您可能需要手动删除脚本。"
            fi
        fi
    fi
    
    # 显示结果
    # Show results
    if [[ ${#removed_files[@]} -gt 0 ]]; then
        if [[ "$lang" == "en" ]]; then
            echo ""
            echo "✅ CCS uninstall completed successfully!"
            echo ""
            echo "Removed files:"
            for file in "${removed_files[@]}"; do
                echo "  - $file"
            done
            echo ""
            echo "Note: Current active configuration (~/.claude/settings.json) was preserved."
            echo ""
            echo "To completely remove CCS, you may also want to:"
            echo "  - Remove the ccs script from your PATH"
        else
            echo ""
            echo "✅ CCS 卸载成功完成！"
            echo ""
            echo "已删除文件："
            for file in "${removed_files[@]}"; do
                echo "  - $file"
            done
            echo ""
            echo "注意：当前激活的配置文件 (~/.claude/settings.json) 已保留。"
            echo ""
            echo "要完全删除 CCS，您还可以："
            echo "  - 从 PATH 中删除 ccs 脚本"
        fi
    else
        if [[ "$lang" == "en" ]]; then
            echo "No CCS files found to remove."
        else
            echo "未找到要删除的 CCS 文件。"
        fi
    fi
}
# Main script logic

# 首次使用设置检查
# First-time setup check
first_time_setup

case "$1" in
    "switch"|"sw")
        # 切换配置
        # Switch configuration
        switch_config "$2"
        ;;
    "add")
        # 添加新配置
        # Add new configuration
        add_config "$2" "$3" "$4"
        ;;
    "delete"|"del"|"rm")
        # 删除配置
        # Delete configuration
        delete_config "$2"
        ;;
    "rename"|"ren"|"mv")
        # 重命名配置
        # Rename configuration
        rename_config "$2" "$3"
        ;;
    "template")
        # 将当前或指定配置设为模板
        # Set current or specified configuration as template
        set_template_config "$2"
        ;;
    "modify"|"mod")
        # 修改配置的API密钥和地址
        # Modify configuration API key and base URL
        if [[ $# -eq 4 ]]; then
            # ccs modify config_name api_key base_url (modify specific config)
            modify_config "$2" "$3" "$4"
        else
            modify_config "" "" ""  # Show usage
        fi
        ;;
    "list"|"ls")
        # 列出所有配置
        # List all configurations
        list_configs_with_current
        ;;
    "uninstall")
        # 卸载 CCS 工具
        # Uninstall CCS tool
        uninstall_ccs
        ;;
    "update")
        # 更新脚本
        # Update script
        lang=$(get_language)
        case "$2" in
            "--rollback"|"-r")
                # 回滚到备份版本
                # Rollback to backup version
                rollback_script "$lang"
                ;;
            "")
                # 默认更新行为：检查并更新
                # Default update behavior: check and update
                update_script "$lang"
                ;;
            *)
                # 无效的子命令
                # Invalid subcommand
                if [[ "$lang" == "en" ]]; then
                    echo -e "${RED}${ICON_ERROR} Unknown update option: ${BOLD}$2${NC}"
                    echo ""
                    echo "Usage: ccs update [option]"
                    echo "Options:"
                    echo "  (none)           Check for updates and update if confirmed"
                    echo "  --rollback, -r   Rollback to previous version"
                else
                    echo -e "${RED}${ICON_ERROR} 未知更新选项: ${BOLD}$2${NC}"
                    echo ""
                    echo "用法: ccs update [选项]"
                    echo "选项:"
                    echo "  (无)             检查更新并在确认后更新"
                    echo "  --rollback, -r   回滚到之前的版本"
                fi
                exit 1
                ;;
        esac
        ;;
    "version"|"-v"|"--version")
        # 显示版本信息
        # Show version information
        show_version
        ;;
    "help"|"-h"|"--help")
        # 显示帮助信息
        # Show help information
        show_help
        ;;
    "")
        # 默认行为：显示帮助信息
        # Default behavior: show help information
        show_help
        ;;
    *)
        # 未知命令
        # Unknown command
        lang=$(get_language)
        if [[ "$lang" == "en" ]]; then
            echo -e "${RED}${ICON_ERROR} Unknown command: ${BOLD}$1${NC}"
            echo -e "${ICON_INFO} Use ${GREEN}'ccs help'${NC} for usage information"
        else
            echo -e "${RED}${ICON_ERROR} 未知命令: ${BOLD}$1${NC}"
            echo -e "${ICON_INFO} 使用 ${GREEN}'ccs help'${NC} 查看使用信息"
        fi
        exit 1
        ;;
esac