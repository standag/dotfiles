sudo sh -c "echo $(which zsh) >> /etc/shells"
chsh -s $(which zsh)

# install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

if [[ ! -e ~/.iterm2  ]]; then
    ln -s Projects/dotenv/configs/iterm2/ ~/.iterm2
fi

if [[ ! -e ~/.zshrc  ]]; then
    ln -s Projects/dotenv/configs/zshrc ~/.zshrc
fi

if [[ ! -e ~/.powerlevel9k  ]]; then
    ln -s Projects/dotenv/configs/powerlevel9k ~/.powerlevel9k
fi

if [[ ! -e ~/.oh-my-zsh/custom/themes/powerlevel9k  ]]; then
    ln -s /usr/local/opt/powerlevel9k ~/.oh-my-zsh/custom/themes/powerlevel9k
fi

if [[ ! -L ~/Library/Application\ Support/Code/User/settings.json ]]; then
    mv ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings_original.json
    ln -s ~/Projects/dotenv/configs/vs_code_settings.json ~/Library/Application\ Support/Code/User/settings.json
fi

# more plugins https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins#keychain