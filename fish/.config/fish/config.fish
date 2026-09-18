# Environment & PATH
set -gx TERM xterm-256color  # force 256-color; some terminals inherit a narrower $TERM
set -gx DOOMDIR $HOME/.config/doom
set -gx EMACSDIR $HOME/.config/emacs
set -gx PATH $HOME/.config/emacs/bin $PATH  # Doom CLI tools (doom sync, etc.)
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.npm-global/bin $PATH  # user-local npm installs (npm config set prefix ~/.npm-global)

# Run Doom Emacs through a persistent daemon. Every invocation opens a terminal
# client frame in the current terminal; file arguments are handled by
# emacsclient, so `emacs README.md` reuses the same Emacs process.
#
# --init-directory is required so a newly started daemon picks up Doom rather
# than ~/.emacs.d.
#
# Under WSL, terminal frames also get a direct-color TERM. Emacs takes its
# colour depth from terminfo alone -- it ignores COLORTERM -- so Windows
# Terminal's xterm-256color quantises every face to the 256-colour cube, which
# flattens catppuccin. The *-direct-wt entries come from ~/.terminfo, built by
# configuration.wsl.nix: ncurses' stock xterm-direct emits the
# colon-separated SGR form, \e[38:2::R:G:Bm, which WT discards along with every
# other colour Emacs draws.
function emacs --description 'Open a terminal Doom Emacs client'
    if not command emacsclient --eval t >/dev/null 2>&1
        command emacs --init-directory $HOME/.config/emacs --daemon; or return
    end

    set -l term $TERM
    if set -q WSL_DISTRO_NAME
        if set -q TMUX
            set term tmux-direct-wt
        else
            set term xterm-direct-wt
        end
    end

    # A daemon keeps both its working directory and Doom workspace between
    # clients. Merely passing the directory would visit it inside the previous
    # workspace, leaving that workspace's old Magit/Treemacs layout visible.
    # For a directory-only launch, explicitly switch Doom to a workspace rooted
    # at the calling shell's cwd and use Dired as its initial buffer.
    set -l open_cwd false
    if test (count $argv) -eq 0
        set open_cwd true
    else if test (count $argv) -eq 1
        switch $argv[1]
            # This wrapper already creates a terminal frame, so these spellings
            # are equivalent to a bare `emacs` invocation.
            case -nw --no-window-system -t --tty
                set open_cwd true
        end
    end

    if $open_cwd
        # Base64 keeps arbitrary path characters out of the Elisp expression.
        set -l encoded_cwd (printf %s "$PWD" | base64 --wrap=0)
        set -l expression "(let ((+workspaces-on-switch-project-behavior t) (+workspaces-switch-project-function #'dired)) (+workspaces-switch-to-project-h (decode-coding-string (base64-decode-string \"$encoded_cwd\") 'utf-8)))"
        TERM=$term command emacsclient -t --eval $expression
    else
        TERM=$term command emacsclient -t $argv
    end
end

function magit --description 'Open Magit status in a terminal Emacs client'
    emacs --eval '(magit-status)'
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

# herdr restores a tab's layout, cwd and scrollback, but respawns a bare shell in
# every pane -- only AI-agent panes are resumed (session.resume_agents_on_restore).
# An editor tab therefore comes back painted from pane history with nothing
# running in it. Relaunch Emacs ourselves when the tab is an editor tab; the tab's
# custom_name survives the restart in ~/.config/herdr/session.json.
#
# INSIDE_EMACS guards the shells Emacs itself spawns (vterm, ansi-term, M-x shell).
# Quitting Emacs returns to this same shell without re-triggering, since
# config.fish is not re-read.
if status is-interactive; and set -q HERDR_PANE_ID; and not set -q INSIDE_EMACS
    set -l _tab (herdr tab get $HERDR_TAB_ID 2>/dev/null | string match -rg '"label":"([^"]*)"')
    if string match -qir 'doom|emacs' -- $_tab
        emacs -nw .
    end
end

# herdr-automatic-rename: live tab naming hook
for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
    test -r "$_f"; and source "$_f"; and break
end
