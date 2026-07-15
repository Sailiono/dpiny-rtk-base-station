param([string]$Port = "COM4", [int]$Baud = 115200)

$p = New-Object System.IO.Ports.SerialPort $Port, $Baud, None, 8, One
$p.ReadTimeout = 2000
$p.Open()
Write-Host "$Port opened"
Start-Sleep -Seconds 1

# Drain
$d = $p.ReadExisting()
if ($d) { Write-Host "Init: $d" }

# Send empty line to trigger prompt
Write-Host ">>> Sending empty line"
$p.WriteLine("")
Start-Sleep -Milliseconds 1000
$d = $p.ReadExisting()
if ($d) { Write-Host "After empty: $d" } else { Write-Host "(nothing)" }

# Send help multiple times
for ($i = 1; $i -le 5; $i++) {
    Write-Host ">>> Attempt ${i}: help"
    $p.WriteLine("help")
    Start-Sleep -Milliseconds 1500
    $d = $p.ReadExisting()
    if ($d) { Write-Host "Response: $d" } else { Write-Host "(nothing)" }
}

# Send single char and wait for echo
Write-Host ">>> Testing echo (sending 'h')"
$p.Write("h")
Start-Sleep -Milliseconds 1000
$d = $p.ReadExisting()
if ($d) { Write-Host "Echo: $d" } else { Write-Host "(no echo)" }

$p.Close()
Write-Host "Done."
