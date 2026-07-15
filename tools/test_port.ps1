param([string]$Port = "COM4", [string]$Name = "VCP")

Write-Host "=== Testing $Name ($Port) ==="
try {
    $p = New-Object System.IO.Ports.SerialPort $Port, 115200, None, 8, One
    $p.ReadTimeout = 5000
    $p.Open()
    Write-Host "$Port OPEN OK"
    Start-Sleep -Milliseconds 2000

    # Drain boot output
    $d = $p.ReadExisting()
    if ($d) { Write-Host "Boot: $d" }
    else { Write-Host "(no boot data)" }

    # Send newline to trigger prompt
    $p.WriteLine("")
    Start-Sleep -Milliseconds 500
    $d = $p.ReadExisting()
    if ($d) { Write-Host "After NL: $d" }

    # Send help
    $p.WriteLine("help")
    Start-Sleep -Milliseconds 1000
    $d = $p.ReadExisting()
    if ($d) { Write-Host "help: $d" }
    else { Write-Host "(no response to help)" }

    $p.Close()
} catch {
    Write-Host "FAIL: $_"
}
