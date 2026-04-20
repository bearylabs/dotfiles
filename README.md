# Bootstrap

## NixOS

Start a temporary shell with git installed

```
nix-shell -p git
```

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles && \
sudo mv /etc/nixos /etc/nixos.backup && \
sudo ln -s ~/dotfiles/nixos /etc/nixos && \
sudo nixos-generate-config && \
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
sudo nix-channel --update && \
sudo nixos-rebuild switch
```
### WSL NixOS

Change Username to desired username first!

```
nix-shell -p git
```

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles && \
sudo rm /etc/nixos/configuration.nix
sudo ln -s ~/dotfiles/nixos/configuration.wsl.nix /etc/nixos/configuration.nix
sudo ln -s ~/dotfiles/nixos/home.nix /etc/nixos/home.nix
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
sudo nix-channel --update && \
sudo nixos-rebuild switch
```

## GNU Stow

On NixOS the dotfiles are linked via the `nixos/` config; on other distros use GNU Stow.

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow . # Stows all dotfiles; use stow <package> to install a single package
```
