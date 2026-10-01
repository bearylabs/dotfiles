function winps --description 'Start Windows PowerShell with Herdr WSL cwd reporting'
    if not set -q WSL_DISTRO_NAME
        echo 'winps: this command is only available inside WSL' >&2
        return 1
    end
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

    command powershell.exe $argv
end
