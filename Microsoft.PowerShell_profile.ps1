Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

# always launch agy with --remote-control flag, this way any local agy session is available at 
# https://antigravity.google.com/ as a seperate remote control instance
function agy {
    $realCmd = Get-Command agy -All | Where-Object { $_.CommandType -notin 'Function', 'Alias' } | Select-Object -First 1
    if ($args -contains '--remote-control' -or $args -contains 'remote-control' -or $args -contains '--help' -or $args -contains '-h' -or $args -contains '--version' -or $args -contains '-v') {
        & $realCmd @args
    } else {
        & $realCmd --remote-control @args
    }
}

# Report current working directory to terminal via OSC 7
function prompt {
    $p = $executionContext.SessionState.Path.CurrentLocation
    if ($p.Provider.Name -eq "FileSystem") {
        $provider_path = $p.ProviderPath -Replace "\\", "/"
        [Console]::Write("$([char]27)]7;file://${env:COMPUTERNAME}/${provider_path}$([char]27)\")
    }
    "PS $p$('>' * ($nestedPromptLevel + 1)) "
}
