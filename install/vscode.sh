extensions=(
    ms-python.python
    eamodio.gitlens
    yzhang.markdown-all-in-one
    ms-azuretools.vscode-docker
    ms-vsliveshare.vsliveshare
    bajdzis.vscode-database
)
for extension in ${extensions[@]}; do
    code --install-extension $extension
done;