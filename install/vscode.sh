extensions=(
    ms-python.python
    eamodio.gitlens
    yzhang.markdown-all-in-one
    ms-azuretools.vscode-docker
    ms-vsliveshare.vsliveshare
    bajdzis.vscode-database
    equinusocio.vsc-material-theme-icons
    johnpapa.vscode-peacock
    2gua.rainbow-brackets
    visualstudioexptteam.vscodeintellicode
    redhat.vscode-yaml
)
for extension in ${extensions[@]}; do
    code --install-extension $extension
done;