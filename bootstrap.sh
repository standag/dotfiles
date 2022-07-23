#!/bin/sh
# install homebrew and homebrew apps
if ! type brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install stow
for item in `ls`; do
    if [[ -d $item ]]; then
        stow $item
    fi
done

brew bundle install

# TODO: add install scripts for fish as default shell, fisher, nvim packager and other nvim install deps
