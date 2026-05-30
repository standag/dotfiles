set shell := ["bash", "-c"]

RED := '\033[0;31m'
NC := '\033[0m'

# Run full bootstrap
default: brew stow-dotfiles stow-skills brew-bundle

# Install Homebrew if missing
brew:
    #!/usr/bin/env bash
    if ! type brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if ! type stow &> /dev/null; then
        brew install stow
    fi

# Stow all dotfile packages to ~
stow-dotfiles:
    #!/usr/bin/env bash
    mkdir -p ~/.config/fish
    for item in */; do
        item="${item%/}"
        [[ "$item" == "skills" ]] && continue
        stow "$item"
    done

# Stow skills to Copilot CLI and Claude Code
stow-skills:
    mkdir -p ~/.copilot/skills ~/.claude/skills
    stow -t ~/.copilot/skills skills
    stow -t ~/.claude/skills skills

# Install all Brewfiles
brew-bundle:
    #!/usr/bin/env bash
    for brew_file in Brewfile*; do
        [[ "$brew_file" == *.json ]] && continue
        echo "Installing $brew_file ..."
        brew bundle install --file "$brew_file"
    done

# Add a third-party skill
skill-add repo name: && stow-skills
    python3 skill-manager.py add {{repo}} {{name}}

# Update a third-party skill
skill-update name: && stow-skills
    python3 skill-manager.py update {{name}}

# Update all third-party skills from registry
skill-update-all: && stow-skills
    #!/usr/bin/env bash
    python3 -c "import json; [print(k) for k in json.load(open('third-party-skills.json'))]" \
        | xargs -I{} python3 skill-manager.py update {}

# Remove a third-party skill
skill-delete name: && stow-skills
    python3 skill-manager.py delete {{name}}
