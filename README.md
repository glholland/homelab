# Homelab 

``` Everything is a work in progress ```

Set up ZSH for Fedora 

```bash
#Install zsh
sudo dnf install zsh yq jq -y
# Install Dev tools for chsh and change the shell to zsh
sudo dnf groupinstall "Development Tools"
echo "/bin/zsh" | sudo tee -a /etc/shells
chsh -s /bin/zsh

# Add ZSH-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# Manually add 'zsh-autosuggestions' to the zsh plugin list and then source the zshrc file
source ~/.zshrc

#Install Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bash_profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#Install vs-code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf check-update
sudo dnf install code

# Install kubctl and autocomplete
sudo dnf install kubernetes-client
source <(kubectl completion zsh)

```