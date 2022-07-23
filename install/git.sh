if [[ ! -e ~/.gitignore  ]]; then
    ln -s Projects/dotenv/configs/gitignore ~/.gitignore
fi

git config --global core.excludesfile '~/.gitignore'