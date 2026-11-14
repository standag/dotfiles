eval "$(/opt/homebrew/bin/brew shellenv)"
set -gx EDITOR hx

alias k kubectl
alias cc /opt/homebrew/bin/claude

# rancher desktop binaries: docker, kubectl, ...
fish_add_path -a ~/.rd/bin

# uv tools
fish_add_path -a ~/.local/bin

zoxide init fish | source
starship init fish | source
fzf --fish | source

set -gx MISE_ACTIVATE_AGGRESSIVE 1
mise activate fish | source

set -gx JIRA_TOKEN $(security find-generic-password -s "dx-jira-token" -w)
