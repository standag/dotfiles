if status is-interactive
    # Commands to run in interactive sessions can go here
end

eval "$(/opt/homebrew/bin/brew shellenv)"
set -gx LDFLAGS "-L/opt/homebrew/lib"
set -gx RUSTFLAGS "-L/opt/homebrew/lib"
set -gx CPPFLAGS "-L/opt/homebrew/include"
set -gx CFLAGS "-L/opt/homebrew/include"

alias k kubectl
alias z zellij

fish_add_path -a /usr/local/opt/python@3.7/bin
fish_add_path -a /usr/local/opt/python@3.8/bin
fish_add_path -a /usr/local/opt/python@3.10/bin

fish_add_path -a ~/.cargo/bin

set -gx USE_GKE_GCLOUD_AUTH_PLUGIN True
fish_add_path -a /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin

# rancher desktop binaries: docker, kubectl, ... # TODO: should I install them separately?
# fish_add_path ~/.rd/bin

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /Users/standag/.ghcup/bin $PATH # ghcup-env

