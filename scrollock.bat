while ($true) {
    $scrollLockState = [console]::NumberLock
    $wsh = New-Object -ComObject WScript.Shell
    $wsh.SendKeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 180
}
