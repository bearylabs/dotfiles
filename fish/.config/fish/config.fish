# Places
set -gx TEERM xterm-256color


if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_prompt
    echo (set_color 87d7af)(date +%H:%M:%S) (set_color 87d7ff)(prompt_pwd) (set_color ffafff)(fish_git_prompt) (set_color ffafff)'→ '
end
