set -e

#-------------------------------------
# Setting up Git
echo "Configuring Git with user name: $GIT_NAME and user email: $GIT_EMAIL"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global safe.directory '*'
git config --global --unset-all safe.directory
git config --global safe.directory '*'
git config --global core.editor "nano"
git config pull.rebase false

echo "Starting SSH agent..."
eval $(ssh-agent -s)

echo "Adding SSH key..."
ssh-add ~/.ssh/id_rsa

echo "Changing ownership of SSH folder..."
chown -R root:root ~/.ssh

#-------------------------------------------
# Setting up Moon
echo "Removing moon cache."
rm -rf .moon/cache