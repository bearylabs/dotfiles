# Disable greeting
set fish_greeting

# Environment & PATH
set -gx TERM xterm-256color  # force 256-color; some terminals inherit a narrower $TERM
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.npm-global/bin $PATH  # user-local npm installs (npm config set prefix ~/.npm-global)

# Let GPG/pinentry ask for passphrases in the current terminal.
if isatty stdin
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
end

# git aliases
alias gs "git status"
alias gc "git commit -m"
alias ga "git add"
alias gd "git diff"

# Git worktree abbreviations. Fish expands these to the full command before
# execution, so the resulting command remains visible and editable.
abbr -a -g gwt git worktree
abbr -a -g gwta git worktree add
abbr -a -g gwtls git worktree list
abbr -a -g gwtlo git worktree lock
abbr -a -g gwtmv git worktree move
abbr -a -g gwtpr git worktree prune
abbr -a -g gwtrm git worktree remove
abbr -a -g gwtulo git worktree unlock

if status is-interactive
    # Commands to run in interactive sessions can go here

    # Windows Terminal (WSL) enables the kitty keyboard protocol, which sends CSI u
    # sequences that break interactive CLI tools (az, ssh-keygen, etc.).
    # Pop the protocol stack before each external command so they see a plain terminal.
    if test -f /proc/version; and grep -qi microsoft /proc/version
        function fish_preexec --on-event fish_preexec
            printf '\e[<u'
        end
    end
end

# Mimics bash's `export VAR=value` syntax
function export
    for arg in $argv
        set -gx (string split -m 1 '=' $arg)
    end
end

# load per-directory env vars via .envrc files
direnv hook fish | source
