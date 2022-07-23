brew tap sambadevi/powerlevel9k

apps=(
     zsh
     httpie
     redis
     pyenv
     pyenv-virtualenv
     powerlevel9k
     mas
     gpg
     pinentry-mac
     postgresql
     curl --with-openssl
     htop
)
for app in ${apps[@]}; do
    if [[ `brew info fish | grep "Not installed"` ]]; then 
        brew install $app
    else
        echo "App $app already exists"
        # brew upgrade $app
    fi
done;

echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
killall gpg-agent