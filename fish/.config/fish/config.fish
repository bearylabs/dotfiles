# Environment & PATH
set -gx TERM xterm-256color  # force 256-color; some terminals inherit a narrower $TERM
set -gx DOOMDIR $HOME/.config/doom
set -gx EMACSDIR $HOME/.config/emacs
set -gx PATH $HOME/.config/emacs/bin $PATH  # Doom CLI tools (doom sync, etc.)
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.npm-global/bin $PATH  # user-local npm installs (npm config set prefix ~/.npm-global)

# --init-directory required so emacs picks up Doom rather than ~/.emacs.d.
#
# Under WSL, terminal frames also get a direct-color TERM. Emacs takes its
# colour depth from terminfo alone -- it ignores COLORTERM -- so Windows
# Terminal's xterm-256color quantises every face to the 256-colour cube, which
# flattens catppuccin. The *-direct-wt entries come from ~/.terminfo, built by
# configuration.wsl.nix: ncurses' stock xterm-direct emits the
# colon-separated SGR form, \e[38:2::R:G:Bm, which WT discards along with every
# other colour Emacs draws.
#
# Only under WSL, since only there does that terminfo entry exist -- a native
# terminal already renders Doom correctly on the stock entry, and an unknown
# TERM would leave Emacs with no terminal description at all.
function emacs --description 'Doom Emacs, truecolor in WSL terminal frames'
    set -l term $TERM
    # Nested rather than joined with `and': fish evaluates conjunctions strictly
    # left to right, so `A; and B; or C' would read as `(A and B) or C' and let
    # a non-WSL `emacs -t' through.
    if set -q WSL_DISTRO_NAME
        if contains -- -nw $argv; or contains -- -t $argv; or contains -- --no-window-system $argv
            if set -q TMUX
                set term tmux-direct-wt
            else
                set term xterm-direct-wt
            end
        end
    end
    TERM=$term command emacs --init-directory $HOME/.config/emacs $argv
end

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


# Mimics bash's `export VAR=value` syntax
function export
    for arg in $argv
        set -gx (string split -m 1 '=' $arg)
    end
end

# load per-directory env vars via .envrc files
direnv hook fish | source
