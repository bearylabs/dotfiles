# dotfiles

Dotfiles for NixOS, NixOS-WSL, Ubuntu, and a minimal native Windows setup.
`dotctl` detects the platform; there is no Nix installation path on Ubuntu or
Windows.

## Bootstrap

Install Git, clone this repository as `~/dotfiles`, then run `dotctl init` with
the desired profile. The command records the selection and applies the required
system, dotfile, tool, and integration configuration.

### Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles
bash ~/dotfiles/dotctl init --profile <profile>
```

Only missing packages listed in `packages/ubuntu-*.txt` are installed. mise is
installed with its official installer when absent. Nix is never installed.

### NixOS

Git may be obtained temporarily before the declarative configuration has been
applied:

```bash
nix-shell -p git --run 'git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles'
bash ~/dotfiles/dotctl init --profile <profile>
```

`init` writes `/etc/nixos/configuration.nix` as a small wrapper that imports
`~/dotfiles/nix/configuration.nix`, then runs `nixos-rebuild switch`. Relative
imports such as `./packages.nix` are still resolved from the repository config,
and the normal generated hardware file remains at
`/etc/nixos/hardware-configuration.nix`.

### NixOS-WSL

```bash
nix-shell -p git --run 'git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles'
bash ~/dotfiles/dotctl init --profile <profile>
```

NixOS-WSL is detected from the NixOS identity plus WSL kernel/environment
markers. `init` writes `/etc/nixos/configuration.nix` as a wrapper that imports
`~/dotfiles/nix/configuration.wsl.nix`, then runs `nixos-rebuild switch`; no
`/etc/nixos` symlink is needed.

### Native Windows (Git Bash)

Install Git for Windows, then start Git Bash from the already open Windows
shell. This deliberately resolves Bash relative to the installed `git.exe`, so
a WSL `bash` cannot be selected accidentally.

From PowerShell:

```powershell
& (Join-Path (Split-Path (Split-Path (Get-Command git.exe).Source)) 'bin\bash.exe') --login -i
```

Or from Command Prompt (`cmd.exe`):

```bat
powershell -NoProfile -Command "$g=Split-Path (Split-Path (Get-Command git.exe).Source); & ($g + '\bin\bash.exe') --login -i"
```

The prompt is now running Git Bash. Verify that `uname -s` starts with `MINGW`
or `MSYS`, then clone into the Windows user profile explicitly and initialize
the repository:

```bash
uname -s
WINDOWS_HOME="$(cygpath -u "$USERPROFILE")"
cd "$WINDOWS_HOME"
git clone https://github.com/bearylabs/dotfiles.git dotfiles
bash "$WINDOWS_HOME/dotfiles/dotctl" init --profile <profile>
```

Windows setup is user-local and does not request administrator rights. If Git
Bash is already running elevated, `dotctl` explicitly permits Scoop's
`-RunAsAdmin` mode while retaining the current user's default Scoop directory
under `%USERPROFILE%`. `dotctl` installs Scoop when absent, updates it, installs
mise through Scoop, installs native prerequisites such as GCC from
`packages/windows-scoop.txt`, and uses `windows/mise.toml` for the minimal
Windows toolset: Node.js, Neovim, Tree-sitter, ripgrep, fd, Lazygit, Pi, Claude
Code, Codex, GitHub Copilot CLI, and Herdr. This tool configuration is copied to
mise's global user config so its shims resolve the managed tools outside the
repository as well. The Windows mise environment selects Scoop's GCC toolchain
for native builds, including Tree-sitter parsers, instead of unavailable MSVC
Build Tools.

Windows does not use Stow or symlinks. The shared Agents, Pi, and Herdr trees are
copied into the corresponding directories below the user profile; Neovim is
copied to `%LOCALAPPDATA%/nvim`. Repository files overwrite older copies, while
unmanaged authentication and session files remain in place. The shared Herdr
configuration is copied unchanged. Bindings and scheduled commands belonging to
Linux-only plugins may therefore fail on Windows; only the Windows plugin list
in `packages/herdr-plugins-windows.txt` is installed.

Scoop installation can still be blocked by corporate PowerShell policy, proxy,
or application-control rules. In that case `dotctl` stops without attempting to
elevate privileges. `-RunAsAdmin` only acknowledges an already elevated shell;
it does not turn the user-local installation into a system-wide installation.

### PATH after bootstrap

`init` creates `~/.local/bin/dotctl`. On Linux this is a symlink; on Windows it
is a Git Bash launcher. Fish configuration in this repository adds that
directory automatically. For the current Bash/Zsh/Git Bash session, or if your
login profile does not already add it, run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then start a new shell or add that export to the machine's login profile.
`dotctl link` warns when the directory is not currently on `PATH`, and
`dotctl doctor` checks it. On Windows, `dotctl` activates mise in both Git Bash
and the current user's Windows PowerShell profile and adds mise's shim directory
to the Windows user `PATH`. New shells can therefore run managed commands such
as `nvim`, `pi`, and `claude` directly. `dotctl` also installs a `gitbash.cmd`
launcher on the Windows user `PATH`, so entering `gitbash` in PowerShell or
Command Prompt opens an interactive Git Bash login shell.

## Profiles

A profile selects machine- or context-specific configuration during `init`. The
selection is stored as one line in `~/.config/dotctl/config` and reused by later
commands. The available profiles are:

- `personal` for personal settings
- `work` for work settings

Switching profiles is safe and idempotent:

```bash
bash ~/dotfiles/dotctl init --profile <profile>
```

Stow simulates changes before applying them and never uses `--adopt`.

## Commands

```text
dotctl init --profile personal|work
dotctl apply [--only system|dotfiles|tools|integrations]
dotctl update
dotctl doctor
dotctl stow
dotctl link
dotctl help
dotctl version
```

Global flags may appear before or after the command:

- `--dry-run` prints mutating commands without running them
- `--yes`, `-y` accepts prompts
- `--verbose`, `-v` prints commands
- `--no-color` disables color

`apply` converges either the complete setup or a selected layer without pulling
the repository. GitHub authentication may open an interactive login; for
non-interactive use, authenticate beforehand or provide `GH_TOKEN`.

`update` fast-forwards the repository when clean, reapplies the setup, refreshes
managed tools and integrations, and runs `doctor`. If the repository has
uncommitted changes, it warns and skips the pull, but updates software using
the current checkout. A clean repository with a detached HEAD or no upstream
still cannot be pulled.

`doctor` performs read-only checks of the current installation.

## Managed tools and integrations

Portable Linux development tools are declared in
`stow/mise/.config/mise/config.toml`; the minimal native Windows toolset is in
`windows/mise.toml`. On Linux, `dotctl` installs mise from `mise.run` into
`~/.local/bin` and uses `mise self-update`. On Windows, Scoop installs and
updates mise and native Windows prerequisites such as GCC, while `dotctl`
copies the Windows mise declaration to the global config shared by Git Bash and
PowerShell. Platform prerequisites live under
`nix/`, `windows/`, and
`packages/`; profile-specific prerequisites are installed by `dotctl` when
needed.

Integration and plugin sources are also declared in `packages/`. `dotctl`
installs and updates them idempotently as part of the normal apply flow.
