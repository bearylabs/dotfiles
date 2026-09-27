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

Dotfiles are linked with GNU Stow on every supported system. Each directory
under `stow/` is an independent package.

```
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --dir="$PWD/stow" --target="$HOME" \
  agents doom fish flameshot ghostty gitconfig herdr i3 i3status \
  mise nvim pi polybar rofi starship tmux zsh
```

## mise

Nix installs mise itself; mise then installs the portable runtimes and developer
CLIs declared in `stow/mise/.config/mise/config.toml`. After stowing the
configuration, install them with:

```
mise install
mise run azure:extensions
```

Fish and Zsh activate mise automatically. Update all mise-managed tools with:

```
mise upgrade
```
