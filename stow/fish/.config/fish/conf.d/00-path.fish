# Bootstrap user-local executables before the remaining conf.d snippets run.
# Fish loads conf.d before config.fish, and mise must be discoverable when
# mise.fish is sourced.
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.npm-global/bin $PATH  # user-local npm installs (npm config set prefix ~/.npm-global)
