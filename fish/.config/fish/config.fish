if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -z $IN_NIX_SHELL
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # set -gx LDFLAGS -L/opt/homebrew/lib
    # set -gx RUSTFLAGS -L/opt/homebrew/lib
    # set -gx CPPFLAGS -L/opt/homebrew/include
    # set -gx CFLAGS -L/opt/homebrew/include
end

set -gx CLOUDSDK_PYTHON python3.9

set -gx EDITOR hx

alias k kubectl
# alias z zellij
alias nomex "poetry run nomex"

# fish_add_path -a /usr/local/opt/python@3.7/bin
# fish_add_path -a /usr/local/opt/python@3.8/bin
# fish_add_path -a /usr/local/opt/python@3.10/bin
# fish_add_path -a /Users/standag/.modular/pkg/packages.modular.com_mojo/bin
# fish_add_path -p /Users/standag/.asdf/shims

# fish_add_path -a ~/.cargo/bin

set -gx USE_GKE_GCLOUD_AUTH_PLUGIN True
fish_add_path -a /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin

# rancher desktop binaries: docker, kubectl, ... 
fish_add_path -a ~/.rd/bin

# set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME
# set -gx PATH $HOME/.cabal/bin /Users/standag/.ghcup/bin $PATH # ghcup-env

# opam configuration
# source /Users/standag/.opam/opam-init/init.fish >/dev/null 2>/dev/null; or true

# uv
fish_add_path "/Users/standag/.local/bin"

zoxide init fish | source
starship init fish | source
