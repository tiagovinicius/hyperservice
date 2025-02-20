set -e

git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global safe.directory '*'
git config --global core.editor "nano"
git config pull.rebase false
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
chown -R root:root ~/.ssh

go install github.com/air-verse/air@latest
