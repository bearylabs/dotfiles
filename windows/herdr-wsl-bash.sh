# Managed by dotctl. Report a marked Git Bash cwd to a Herdr server in WSL.
# HERDR_WSL_INTEROP is supplied by the WSL powershell.exe/winps wrapper and is
# inherited when that PowerShell starts Git Bash.
if [[ ${HERDR_WSL_INTEROP:-} == 1 && -z ${__HERDR_WSL_BASH_PROMPT_INSTALLED:-} ]]; then
  __HERDR_WSL_BASH_PROMPT_INSTALLED=1
  __HERDR_WSL_LAST_WINDOWS_PATH=
  __HERDR_WSL_LAST_REPORTED_PATH=

  __herdr_wsl_bash_prompt() {
    local windows_path drive tail wsl_path converted
    windows_path=$(pwd -W 2>/dev/null) || return
    [[ $windows_path != "$__HERDR_WSL_LAST_WINDOWS_PATH" ]] || return
    __HERDR_WSL_LAST_WINDOWS_PATH=$windows_path

    if [[ $windows_path =~ ^([A-Za-z]):[/\\]?(.*)$ ]]; then
      drive=${BASH_REMATCH[1],,}
      tail=${BASH_REMATCH[2]//\\//}
      wsl_path="${HERDR_WSL_MOUNT_ROOT:-/mnt}/$drive"
      [[ -z $tail ]] || wsl_path+="/$tail"
    elif [[ -n ${HERDR_WSL_DISTRO:-} ]]; then
      # Unusual paths (including UNC paths) are converted only after cd.
      converted=$(MSYS_NO_PATHCONV=1 wsl.exe -d "$HERDR_WSL_DISTRO" \
        -e wslpath -u -- "$windows_path" 2>/dev/null) || return
      wsl_path=${converted%$'\r'}
    else
      return
    fi

    [[ -n $wsl_path && $wsl_path != "$__HERDR_WSL_LAST_REPORTED_PATH" ]] || return
    __HERDR_WSL_LAST_REPORTED_PATH=$wsl_path
    printf '\e]9;9;%s\e\\' "$wsl_path"
  }

  if declare -p PROMPT_COMMAND 2>/dev/null | grep -q '^declare -a'; then
    PROMPT_COMMAND=(__herdr_wsl_bash_prompt "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="__herdr_wsl_bash_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
  fi
fi
