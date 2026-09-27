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

`init` selects `nix/configuration.nix` and runs `nixos-rebuild switch`. That
configuration expects the normal generated hardware file at
`/etc/nixos/hardware-configuration.nix`.

### NixOS-WSL

```bash
nix-shell -p git --run 'git clone https://github.com/bearylabs/dotfiles.git ~/dotfiles'
bash ~/dotfiles/dotctl init --profile <profile>
```

NixOS-WSL is detected from the NixOS identity plus WSL kernel/environment
markers. `nix/configuration.wsl.nix` is passed directly to
`nixos-rebuild switch`; no `/etc/nixos` symlink is needed.

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

`update` safely fast-forwards the repository, reapplies the setup, refreshes
managed tools and integrations, and runs `doctor`. It refuses repository states
that cannot be updated without ambiguity.

`doctor` performs read-only checks of the current installation.

## Managed tools and integrations

Portable development tools are declared in
`stow/mise/.config/mise/config.toml`. Platform prerequisites live under `nix/`
and `packages/`; profile-specific prerequisites are installed by `dotctl` when
needed.

Integration and plugin sources are also declared in `packages/`. `dotctl`
installs and updates them idempotently as part of the normal apply flow.
