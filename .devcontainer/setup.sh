set -e

git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global safe.directory '*'

go install github.com/air-verse/air@latest

bash <(curl -fsSL https://moonrepo.dev/install/moon.sh)
export PATH="$HOME/.moon/bin:$PATH"
# Define the PATH export statement
export_statement='export PATH="$HOME/.moon/bin:$PATH"'
# Check the current shell
current_shell=$(basename "$SHELL")
# Add the export statement to the appropriate file based on the shell
if [[ "$current_shell" == "bash" ]]; then
    # Add to .bashrc or .bash_profile depending on what exists
    if [ -f "$HOME/.bashrc" ]; then
        echo "$export_statement" >> "$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        echo "$export_statement" >> "$HOME/.bash_profile"
    else
        echo "$export_statement" >> "$HOME/.bashrc"
    fi
elif [[ "$current_shell" == "zsh" ]]; then
    # Add to .zshrc for Zsh users
    if [ -f "$HOME/.zshrc" ]; then
        echo "$export_statement" >> "$HOME/.zshrc"
    else
        echo "$export_statement" >> "$HOME/.zshrc"
    fi
else
    # For any other shell, we default to adding it to .bashrc
    echo "$export_statement" >> "$HOME/.bashrc"
fi
# Output a message indicating completion
echo "Added the custom PATH export to shell."