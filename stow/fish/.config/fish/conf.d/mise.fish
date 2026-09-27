# Add mise-managed tools to PATH and update the environment when changing
# directories. The guard keeps Fish usable during the initial Nix bootstrap.
if command -q mise
    mise activate fish | source
end
