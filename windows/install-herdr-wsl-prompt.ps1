$ErrorActionPreference = 'Stop'
$marker = '# Managed by dotctl: Herdr WSL cwd reporting'

# Older dotctl versions installed the loader in CurrentUserAllHosts. That file
# runs before CurrentUserCurrentHost, so a later Starship setup could replace
# the wrapped prompt. Remove only the exact managed three-line loader.
$legacyPath = $PROFILE.CurrentUserAllHosts
if (Test-Path -LiteralPath $legacyPath) {
    $lines = @(Get-Content -LiteralPath $legacyPath)
    $updated = [System.Collections.Generic.List[string]]::new()
    $changed = $false
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -eq $marker -and
            $index + 2 -lt $lines.Count -and
            $lines[$index + 1] -match 'herdr-wsl-prompt\.ps1' -and
            $lines[$index + 2] -match '^if \(Test-Path -LiteralPath \$herdrWslPrompt\)') {
            $index += 2
            $changed = $true
            continue
        }
        $updated.Add($lines[$index])
    }
    if ($changed) {
        Set-Content -LiteralPath $legacyPath -Value $updated -Encoding UTF8
    }
}

# CurrentUserCurrentHost runs after the user's host-specific profile and prompt
# setup, so the Herdr wrapper sees the final Starship/custom prompt function.
$profilePath = $PROFILE.CurrentUserCurrentHost
$content = if (Test-Path -LiteralPath $profilePath) {
    Get-Content -LiteralPath $profilePath -Raw
} else {
    ''
}
if (-not $content.Contains($marker)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $profilePath) -Force | Out-Null
    $block = "`r`n$marker`r`n`$herdrWslPrompt = [IO.Path]::Combine(`$env:USERPROFILE, `".config`", `"dotctl`", `"herdr-wsl-prompt.ps1`")`r`nif (Test-Path -LiteralPath `$herdrWslPrompt) { . `$herdrWslPrompt }`r`n"
    Add-Content -LiteralPath $profilePath -Value $block -Encoding UTF8
}
