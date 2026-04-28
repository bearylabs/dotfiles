# Places
set -gx TERM xterm-256color
set -gx DOOMDIR $HOME/.config/doom
set -gx EMACSDIR $HOME/.config/emacs
set -gx PATH $HOME/.config/emacs/bin $PATH 
set -gx PATH $HOME/.local/bin $PATH

alias emacs "emacs --init-directory $HOME/.config/emacs"

# git aliases
alias gs "git status"
alias gc "git commit -m"
alias ga "git add"
alias gd "git diff"

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

function fish_prompt
    echo (set_color 87d7af)(date +%H:%M:%S) (set_color 87d7ff)(prompt_pwd) (set_color ffafff)(fish_git_prompt) (set_color ffafff)'→ '
end
