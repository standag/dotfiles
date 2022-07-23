# install homebrew and homebrew apps
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
bash install/cask.sh
bash install/brew.sh

# setup zsh, oh-my-shell, and iTerm2
bash install/zsh.sh

bash install/app_store.sh

