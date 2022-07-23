if status is-interactive
    # Commands to run in interactive sessions can go here
end

eval "$(/opt/homebrew/bin/brew shellenv)"

alias k kubectl

set -gx LDFLAGS ""
set -gx CPPFLAGS ""

fish_add_path -a /usr/local/opt/python@3.7/bin
fish_add_path -a /usr/local/opt/python@3.8/bin
fish_add_path -a /usr/local/opt/python@3.10/bin

fish_add_path -a ~/.cargo/bin

fish_add_path /usr/local/opt/curl/bin
set -gxa LDFLAGS "-L/usr/local/opt/curl/lib "
set -gxa CPPFLAGS "-I/usr/local/opt/curl/include "

fish_add_path /usr/local/opt/openssl@1.1/bin
set -gxa LDFLAGS "-L/usr/local/opt/openssl@1.1/lib "
set -gxa CPPFLAGS "-I/usr/local/opt/openssl@1.1/include "

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /Users/standag/.ghcup/bin $PATH # ghcup-env

