if status is-interactive
    # Commands to run in interactive sessions can go here
end

eval "$(/opt/homebrew/bin/brew shellenv)"
set -gx CLOUDSDK_PYTHON python3.9
set -gx EDITOR hx

alias k kubectl
# alias z zellij
alias cc /opt/homebrew/bin/claude

# fish_add_path -a /usr/local/opt/python@3.7/bin
# fish_add_path -a /usr/local/opt/python@3.8/bin
# fish_add_path -a /usr/local/opt/python@3.10/bin
# fish_add_path -a /Users/standag/.modular/pkg/packages.modular.com_mojo/bin
# fish_add_path -p /Users/standag/.asdf/shims

# fish_add_path -a ~/.cargo/bin

set -gx USE_GKE_GCLOUD_AUTH_PLUGIN True
fish_add_path -a /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin

# set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME
# set -gx PATH $HOME/.cabal/bin /Users/standag/.ghcup/bin $PATH # ghcup-env

# opam configuration
# source /Users/standag/.opam/opam-init/init.fish >/dev/null 2>/dev/null; or true

# rancher desktop binaries: docker, kubectl, ... 
fish_add_path -a ~/.rd/bin

# uv tools
fish_add_path -a ~/.local/bin

zoxide init fish | source
starship init fish | source
fzf --fish | source
fnm env --use-on-cd --version-file-strategy=recursive --shell fish | source

set -gx MISE_ACTIVATE_AGGRESSIVE 1
mise activate fish | source

set -gx JIRA_TOKEN $(security find-generic-password -s "dx-jira-token" -w)
