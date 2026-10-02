# Disable greeting
set fish_greeting

# Environment
set -gx TERM xterm-256color  # force 256-color; some terminals inherit a narrower $TERM

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
    # Reuse one SSH agent instead of starting a new process for every shell.
    # Keep an already inherited, reachable agent; otherwise use a stable socket.
    set -l ssh_agent_available false
    if set -q SSH_AUTH_SOCK; and test -S "$SSH_AUTH_SOCK"
        command ssh-add -l >/dev/null 2>&1
        if test $status -ne 2
            set ssh_agent_available true
        end
    end

    if not $ssh_agent_available
        if set -q XDG_RUNTIME_DIR
            set -l runtime_dir (string replace -r '/+$' '' -- "$XDG_RUNTIME_DIR")
            set -gx SSH_AUTH_SOCK "$runtime_dir/ssh-agent.socket"
        else
            set -gx SSH_AUTH_SOCK "$HOME/.cache/ssh-agent/socket"
        end

        command ssh-add -l >/dev/null 2>&1
        if test $status -eq 2
            mkdir -p (dirname "$SSH_AUTH_SOCK")
            rm -f "$SSH_AUTH_SOCK"
            eval (command ssh-agent -c -a "$SSH_AUTH_SOCK") >/dev/null
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
