# Dotfiles Managed with GNU Stow

This repository contains my personal dotfiles, which are managed using **GNU Stow**. The goal of this setup is to keep my configuration files organized and easily deployable across different machines.

## 🚀 Quick Start

1. **Clone the repository**:
   First, clone this repository to your local machine:
   ```bash
   git clone https://github.com/bearylabs/dotfiles.git ~/
   cd ~/dotfiles
   ```

2. **Install GNU Stow**:
   Make sure **GNU Stow** is installed on your system. If it’s not already installed, you can install it via your package manager:

   - On Debian-based systems (Ubuntu, etc.):
     ```bash
     sudo apt install stow
     ```
   - On macOS (with Homebrew):
     ```bash
     brew install stow
     ```

3. **Stow your configurations**:
   To apply your configurations, use **GNU Stow**. The general format is:
   ```bash
   stow <folder_name>
   ```
   Example: To stow your **zsh** configuration:
   ```bash
   stow zsh
   ```

4. **Check the result**:
   After running the `stow` command, your configuration files will be symlinked to their appropriate locations (e.g., `~/.zshrc`, `~/.vimrc`, etc.).

## 📁 Directory Structure

Here's a brief overview of the directory structure and how your dotfiles are organized:

```
dotfiles/
├── nvim/
│   ├── init.vim
│   └── .vimrc
├── zsh/
│   ├── .zshrc
│   └── .zshenv
├── tmux/
│   └── .tmux.conf
└── README.md
```

Each subdirectory (e.g., `zsh`, `nvim`, `tmux`) contains the configuration files for a specific tool or application. When you run `stow <tool_name>`, it creates symlinks for those files in the appropriate locations.

## 🛠️ Managing Dotfiles

### Adding a new configuration

To add a new configuration for a tool or application, create a new directory in the root of the repository (e.g., `vim`, `git`, `alacritty`) and add the corresponding configuration files. Once the files are ready, use `stow` to link them:

```bash
stow <new_tool_name>
```

### Removing a configuration

To remove a stowed configuration, simply run:

```bash
stow -D <tool_name>
```

This will remove the symlinks for that tool and restore your system to its original state.

## ⚡ Advanced Usage

You can also stow multiple tools at once by specifying a space-separated list of directories:

```bash
stow zsh vim tmux
```

To **unstow** multiple directories:

```bash
stow -D zsh vim tmux
```

### Dry-run

If you want to see what changes will be made without actually applying them, you can run **stow** in **dry-run mode**:

```bash
stow -n <tool_name>
```

## 📝 Customizing the Setup

Feel free to modify the configurations in each folder. If you'd like to tweak your **zsh** settings, for example, simply edit the `~/.zshrc` file in the `zsh/` folder and apply it by running `stow zsh` again.

### Configuring Stow for Subfolders

If you want to specify particular subfolders for Stow to manage, you can run:

```bash
stow --dir=<path_to_dotfiles> <tool_name>
```

## 🧳 Backup and Sync

You can use this repository to sync your dotfiles across multiple machines. Simply clone the repository on your new machine and run `stow` to apply the configurations:

```bash
git clone https://github.com/your-username/dotfiles.git ~/
cd ~/dotfiles
stow <tool_name>
```

## 👥 Contributing

If you’d like to contribute or share your dotfiles, feel free to fork this repository and make a pull request! Any improvements are welcome.

## 💬 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
