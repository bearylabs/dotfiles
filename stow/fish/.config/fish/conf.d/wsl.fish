# WSL-only shell integration and Windows interoperability helpers.
# Fish loads conf.d snippets automatically before config.fish.
if not set -q WSL_DISTRO_NAME
    return
end

if status is-interactive
    # Windows Terminal enables the kitty keyboard protocol, which sends CSI u
    # sequences that break interactive CLI tools (az, ssh-keygen, etc.).
    # Pop the protocol stack before each external command so they see a plain terminal.
    function fish_preexec --on-event fish_preexec
        printf '\e[<u'
    end
end

function winps --description 'Start Windows PowerShell with Herdr WSL cwd reporting'
    if not command -q powershell.exe
        echo 'winps: powershell.exe is not available through WSL interop' >&2
        return 1
    end

    set -lx HERDR_WSL_INTEROP 1
    set -lx HERDR_WSL_DISTRO $WSL_DISTRO_NAME
    set -lx HERDR_WSL_MOUNT_ROOT /mnt

    set -l bridge_vars HERDR_WSL_INTEROP HERDR_WSL_DISTRO HERDR_WSL_MOUNT_ROOT
    set -l inherited_wsl_env
    if set -q WSLENV; and test -n "$WSLENV"
        set inherited_wsl_env $WSLENV
    end
    set -lx WSLENV (string join : $bridge_vars $inherited_wsl_env)

    # Mark the containing Herdr workspace while its Windows shell is active.
    # A pane-specific metadata source avoids colliding with another winps pane.
    set -l metadata_reported false
    set -l metadata_source
    set -l herdr_bin
    if set -q HERDR_WORKSPACE_ID HERDR_PANE_ID
        if set -q HERDR_BIN_PATH; and test -x "$HERDR_BIN_PATH"
            set herdr_bin $HERDR_BIN_PATH
        else if command -q herdr
            set herdr_bin (command -s herdr)
        end
        if test -n "$herdr_bin"
            set metadata_source "dotfiles:winps:$HERDR_PANE_ID"
            if command "$herdr_bin" workspace report-metadata "$HERDR_WORKSPACE_ID" \
                    --source "$metadata_source" --token 'windows=' >/dev/null 2>&1
                set metadata_reported true
            end
        end
    end

    command powershell.exe $argv
    set -l powershell_status $status

    if $metadata_reported
        command "$herdr_bin" workspace report-metadata "$HERDR_WORKSPACE_ID" \
            --source "$metadata_source" --clear-token windows >/dev/null 2>&1
    end

    return $powershell_status
end
