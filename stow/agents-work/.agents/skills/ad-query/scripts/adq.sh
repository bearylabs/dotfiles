#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: adq.sh [--json] '<PowerShell>'
       echo '<PowerShell>' | adq.sh [--json]

Run a read-only Active Directory query from WSL through Windows PowerShell 5.1
(RSAT ActiveDirectory module) with the stored admin credential.

All *-AD* cmdlets get -Credential and -Server set automatically.
--json  pipe the result through ConvertTo-Json -Depth 4 (use with Select-Object).

Environment:
  ADQ_CRED_FILE  credential file name in %USERPROFILE% (default: t1-rudek.xml)
  ADQ_SERVER     domain or DC (default: group.siempelkamp.com)
  ADQ_USER       account for setup hint (default: GROUP\t1.rudek)

Write cmdlets (Set-/New-/Remove-/Add-/... -AD*) are refused.
USAGE
}

json=0
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --json) json=1; shift ;;
esac

if [[ $# -gt 0 ]]; then
  query="$*"
elif [[ ! -t 0 ]]; then
  query="$(cat)"
else
  usage; exit 2
fi

cred_file="${ADQ_CRED_FILE:-t1-rudek.xml}"
server="${ADQ_SERVER:-group.siempelkamp.com}"
user="${ADQ_USER:-GROUP\\t1.rudek}"

# Read-only guard: refuse AD write cmdlets and obvious escape hatches.
write_re='(^|[^A-Za-z])(Set|New|Remove|Add|Enable|Disable|Unlock|Move|Rename|Clear|Reset|Restore|Grant|Revoke|Install|Uninstall|Sync)-AD[A-Za-z]*'
escape_re='(Invoke-Expression|(^|[^A-Za-z])iex([^A-Za-z]|$)|Invoke-Command|Start-Process|EncodedCommand|\[scriptblock\])'
if grep -qiE "$write_re" <<<"$query"; then
  echo "adq: refused - query contains an AD write cmdlet. This tool is read-only." >&2
  exit 3
fi
if grep -qiE "$escape_re" <<<"$query"; then
  echo "adq: refused - dynamic code execution is not allowed." >&2
  exit 3
fi

if (( json )); then
  query="$query | ConvertTo-Json -Depth 4"
fi

ps_script=$(cat <<PS
\$ErrorActionPreference = 'Stop'
\$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
\$f = Join-Path \$env:USERPROFILE '$cred_file'
if (-not (Test-Path \$f)) { exit 4 }
Import-Module ActiveDirectory -WarningAction SilentlyContinue
\$PSDefaultParameterValues['*-AD*:Credential'] = Import-Clixml \$f
\$PSDefaultParameterValues['*-AD*:Server'] = '$server'
try {
$query
} catch {
  [Console]::Error.WriteLine("adq: " + \$_.Exception.Message)
  exit 1
}
PS
)

encoded=$(printf '%s' "$ps_script" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)
set +e
powershell.exe -NoProfile -NonInteractive -EncodedCommand "$encoded" | tr -d '\r'
rc=${PIPESTATUS[0]}
set -e

if (( rc == 4 )); then
  cat >&2 <<EOF
adq: credential file %USERPROFILE%\\$cred_file is missing.
Setup (user must run this interactively, it opens a password prompt):
  powershell.exe -NoProfile -Command 'Get-Credential "$user" | Export-Clixml "\$env:USERPROFILE\\$cred_file"'
EOF
fi
exit "$rc"
