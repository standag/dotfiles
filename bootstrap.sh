#!/bin/sh
# install homebrew and homebrew apps
if ! type brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! type stow; then 
    brew install stow
fi

for item in `ls`; do
    if [[ -d $item ]]; then
        stow $item
    fi
done

brew bundle install

if [[ -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]]; then
    echo "packer installed"
else
    echo "packer installing..."
    git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
fi

fish_plugins="jorgebucaran/fisher jhillyerd/plugin-git"
for plugin in $fish_plugins; do
    echo "fish plugin: $plugin"
    if ! grep $plugin ~/.config/fish/fish_plugins 2>&1 > /dev/null; then
        echo "...mising"
    else
        echo "...already installed"
    fi
done
