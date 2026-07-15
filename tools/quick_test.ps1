# Quick serial port test
param([string]$Port = "COM4", [int]$Baud = 115200)

Write-Host "Testing $Port..."
try {
    $p = New-Object System.IO.Ports.SerialPort $Port, $Baud, None, 8, One
    $p.ReadTimeout = 5000
    $p.Open()
    Write-Host "$Port OPEN OK"
    Start-Sleep -Seconds 2
    $data = $p.ReadExisting()
    if ($data) {
        Write-Host "=== Boot Output ==="
        Write-Host $data
    } else {
        Write-Host "(no initial data)"
        Write-Host "Sending newline..."
        $p.WriteLine("")
        Start-Sleep -Milliseconds 500
        $data = $p.ReadExisting()
        Write-Host $data
    }
    $p.Close()
} catch {
    Write-Host "FAIL: $_"
    exit 1
}
