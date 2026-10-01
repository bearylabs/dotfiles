# Managed by dotctl. Report an interop PowerShell cwd to a Herdr server in WSL.
# The winps Fish function supplies these variables only for marked WSL sessions.
if ($env:HERDR_WSL_INTEROP -eq '1' -and
    $null -eq $global:__HerdrWslOriginalPrompt) {

    function global:ConvertTo-HerdrWslPath {
        param(
            [Parameter(Mandatory)]
            [string] $WindowsPath
        )

        $mountRoot = if ($env:HERDR_WSL_MOUNT_ROOT) {
            $env:HERDR_WSL_MOUNT_ROOT.TrimEnd('/')
        } else {
            '/mnt'
        }

        # Avoid starting wsl.exe for ordinary Windows drive paths.
        if ($WindowsPath -match '^(?<Drive>[A-Za-z]):(?:\\(?<Tail>.*))?$') {
            $drive = $Matches.Drive.ToLowerInvariant()
            $tail = $Matches.Tail
            if ([string]::IsNullOrEmpty($tail)) {
                return "$mountRoot/$drive"
            }
            return "$mountRoot/$drive/$(($tail -replace '\\', '/'))"
        }

        # Map a path into the calling WSL distribution directly.
        if ($WindowsPath -match '^\\\\wsl(?:\.localhost|\$)\\(?<Distro>[^\\]+)(?:\\(?<Tail>.*))?$') {
            $distro = $Matches.Distro
            $tail = $Matches.Tail
            if ($distro -eq $env:HERDR_WSL_DISTRO) {
                if ([string]::IsNullOrEmpty($tail)) {
                    return '/'
                }
                return '/' + ($tail -replace '\\', '/')
            }
        }

        # Keep unusual but WSL-accessible paths working. The prompt caches the
        # Windows cwd, so this fallback runs at most once per directory change.
        if ($env:HERDR_WSL_DISTRO) {
            $converted = @(
                & wsl.exe -d $env:HERDR_WSL_DISTRO -e wslpath -u -- $WindowsPath 2>$null
            )
            if ($LASTEXITCODE -eq 0 -and $converted.Count -gt 0) {
                return ([string] $converted[0]).Trim()
            }
        }

        return $null
    }

    $global:__HerdrWslOriginalPrompt = $function:prompt
    $global:__HerdrWslLastWindowsPath = $null
    $global:__HerdrWslLastReportedPath = $null

    function global:prompt {
        # Invoke the existing prompt first so it still sees the previous
        # command's $? value.
        $out = @(& $global:__HerdrWslOriginalPrompt) -join ' '
        $savedLastExitCode = $global:LASTEXITCODE
        $loc = $ExecutionContext.SessionState.Path.CurrentLocation

        if ($loc.Provider.Name -eq 'FileSystem') {
            $windowsPath = $loc.ProviderPath
            if ($windowsPath -ne $global:__HerdrWslLastWindowsPath) {
                $global:__HerdrWslLastWindowsPath = $windowsPath
                $wslPath = ConvertTo-HerdrWslPath -WindowsPath $windowsPath
                if ($wslPath -and $wslPath -ne $global:__HerdrWslLastReportedPath) {
                    $global:__HerdrWslLastReportedPath = $wslPath
                    $esc = [string][char]27
                    $out += $esc + ']9;9;' + $wslPath + $esc + '\'
                }
            }
        }

        $global:LASTEXITCODE = $savedLastExitCode
        $out
    }
}
