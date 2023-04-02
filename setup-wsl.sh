#!/bin/bash

touch $HOME/.hushlogin
sudo apt upgrade
sudo apt install neovim
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt update
sudo apt install fish
chsh -s /usr/bin/fish

Relaunch shell
# # Copy config of fish
curl -sS https://starship.rs/install.sh | sh
Copy starship config to ~/.config/starship.toml

# Copy ssh keys to ~/.ssh
chmod 600 $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub

gpg --import key.pk
echo -e "pinentry-program \"/mnt/c/Users/raxl8/scoop/apps/git/current/usr/bin/pinentry.exe\"\ndefault-cache-ttl 34560000\nmax-cache-ttl 34560000" | tee -a $HOME/.gnupg/gpg-agent.conf
gpgconf --reload gpg-agent

sudo apt-get install ca-certificates curl gnupg
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
echo -e "[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf
