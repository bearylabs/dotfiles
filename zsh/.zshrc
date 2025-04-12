export PATH=$PATH:/snap/bin
export TERM=xterm


# Save zsh History
HISTFILE=~/.zsh_history

# Max number of entries in the history file
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY             # Don’t overwrite, just append
setopt HIST_IGNORE_DUPS          # Don’t record duplicate commands
setopt SHARE_HISTORY             # Share history across all sessions
setopt INC_APPEND_HISTORY_TIME   # Save each command immediately with timestamp



neofetch
