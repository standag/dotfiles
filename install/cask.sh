brew tap homebrew/cask-fonts

apps=(
    slack
    google-chrome
    iterm2
    1password
    visual-studio-code
    postico
    docker
    dropbox
    vlc
    keybase
    font-awesome-terminal-fonts
    karabiner-elements
    spotify
)
for app in ${apps[@]}; do
    if [[ -d /Applications/$app.app ]]; then
        echo "App $app already exists"
    else
        brew cask install $app
    fi
done;