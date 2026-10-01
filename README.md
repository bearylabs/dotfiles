# dotfiles

Linux dotfiles for NixOS, NixOS-WSL, and Ubuntu. `dotctl` detects the platform;
there is no Nix installation path on Ubuntu.

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

### PATH after bootstrap

`init` creates `~/.local/bin/dotctl`. Fish configuration in this repository adds
that directory automatically. For the current Bash/Zsh session, or if your
login profile does not already add it, run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then start a new shell or add that export to the machine's login profile.
`dotctl link` warns when the directory is not currently on `PATH`, and
`dotctl doctor` checks it.

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

Portable development tools are declared in
`stow/mise/.config/mise/config.toml`. `dotctl` installs mise itself from
`mise.run` into `~/.local/bin` and runs `mise self-update` before updating
mise-managed tools. Platform prerequisites live under `nix/` and `packages/`;
profile-specific prerequisites are installed by `dotctl` when needed.

Integration and plugin sources are also declared in `packages/`. `dotctl`
installs and updates them idempotently as part of the normal apply flow.
