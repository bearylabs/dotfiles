# Bootstrap

## NixOS

```
nix-shell -p git
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
sudo rm -rf /etc/nixos
sudo ln -s ~/dotfiles/nixos /etc/nixos
sudo nixos-generate-config
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
sudo nix-channel --update
sudo nixos-rebuild switch
```

## GNU Stow
On NixOS the dotfiles are linked via the `nixos/` config; on other distros use GNU Stow.
```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow . # Stows all dotfiles; use stow <package> to install a single package
```

