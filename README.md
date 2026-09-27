# Bootstrap

## NixOS

Start a temporary shell with git installed

```
nix-shell -p git
```

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles && \
sudo mv /etc/nixos /etc/nixos.backup && \
sudo ln -s ~/dotfiles/nix /etc/nixos && \
sudo nixos-generate-config && \
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos && \
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
sudo ln -s ~/dotfiles/nix/configuration.wsl.nix /etc/nixos/configuration.nix
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos && \
sudo nix-channel --update && \
sudo nixos-rebuild switch
```

## Updating Packages

Update channels and rebuild to get the latest packages:

```
sudo nix-channel --update && \
sudo nixos-rebuild switch
```

To garbage-collect old generations and free disk space:

```
sudo nix-collect-garbage -d
```

## GNU Stow

On NixOS the dotfiles are linked via the `nix/` config; on other distros use GNU Stow.

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow agents doom fish flameshot ghostty gitconfig herdr i3 i3status \
  nvim pi polybar rofi starship tmux zsh
```
