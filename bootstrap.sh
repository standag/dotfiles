#!/bin/sh

RED='\033[0;31m'
NC='\033[0m'

# install homebrew and homebrew apps
if ! type brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/standag/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! type stow; then 
    brew install stow
fi

# if [[ -f ~/.config/fish/config.fish ]]; then
#     rm ~/.config/fish/config.fish
# fi

mkdir -p ~/.config/fish ~/.agents

for item in `ls`; do
    if [[ -d $item ]] && [[ $item != "skills" ]]; then
        stow $item
    fi
done

mkdir -p ~/.copilot/skills ~/.claude/skills
stow -t ~/.copilot/skills skills
stow -t ~/.claude/skills skills

for brew_file in `ls Brewfile*`; do
    if [[ $brew_file != *.json ]]; then
        echo Instaling $brew_file ...
        brew bundle install --file $brew_file
    fi

done

# install tools from ~/.config/mise/config.toml
echo "Installing mise tools ..."
mise install

echo "${RED}Don't forgot install fisher plugins! Hint: fisher update$NC"
