# Diagnose and test serial ports
Write-Host "=== COM Port Scan ==="
[System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object | ForEach-Object {
    try {
        $p = New-Object System.IO.Ports.SerialPort $_, 115200, None, 8, One
        $p.Open()
        Write-Host "$_ : OPEN OK"
        Start-Sleep -Milliseconds 2000
        $data = $p.ReadExisting()
        if ($data) {
            Write-Host "  DATA: $data"
        } else {
            Write-Host "  (no data)"
            # Try sending newline to trigger prompt
            $p.WriteLine("")
            Start-Sleep -Milliseconds 1000
            $data2 = $p.ReadExisting()
            if ($data2) {
                Write-Host "  AFTER NL: $data2"
            }
        }
        $p.Close()
    } catch {
        Write-Host "$_ : ERROR - $_"
    }
}

Write-Host "`n=== Handle check for COM ports ==="
# Use PowerShell to check for open file handles
Get-Process | ForEach-Object {
    $proc = $_
    try {
        $proc.Modules | Where-Object { $_.ModuleName -like "*serial*" -or $_.ModuleName -like "*uart*" } | ForEach-Object {
            Write-Host "Process using serial: $($proc.ProcessName) (PID: $($proc.Id))"
        }
    } catch {}
}
Write-Host "Done."
