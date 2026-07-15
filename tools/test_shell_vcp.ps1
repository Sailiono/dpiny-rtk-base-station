# dpiny-RTK Shell & VCP Automated Test
# Tests shell on both USB CDC VCP (COM4) and USART3 (COM11)

param(
    [string]$VcpPort = "COM4",
    [string]$UartPort = "COM11",
    [int]$BaudRate = 115200,
    [int]$TimeoutMs = 3000
)

$ErrorActionPreference = "Stop"
$testResults = @()
$passed = 0
$failed = 0

function Test-Port {
    param([string]$Port, [string]$Name)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Testing $Name ($Port) @ $BaudRate baud" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        $portObj = New-Object System.IO.Ports.SerialPort $Port, $BaudRate, None, 8, One
        $portObj.ReadTimeout = $TimeoutMs
        $portObj.NewLine = "`n"
        $portObj.Open()
        Write-Host "[INFO] Port opened" -ForegroundColor Green
    }
    catch {
        Write-Host "[FAIL] Cannot open $Port : $_" -ForegroundColor Red
        $script:failed++
        $script:testResults += [PSCustomObject]@{Port=$Name; Test="OPEN"; Result="FAIL"; Detail=$_.Exception.Message}
        return
    }

    # Drain any initial boot output
    Start-Sleep -Milliseconds 500
    try {
        while ($portObj.BytesToRead -gt 0) {
            $drain = $portObj.ReadExisting()
            Write-Host "[BOOT] $drain" -ForegroundColor DarkGray
        }
    } catch { }

    # Test helper: send command, read response, check keywords
    function Invoke-ShellTest {
        param([string]$Cmd, [string]$TestName, [string[]]$ExpectedKeywords, [int]$WaitMs = 500)

        Write-Host "`n--- Test: $TestName ---" -ForegroundColor Yellow
        Write-Host "  Send: '$Cmd'"

        # Send command
        $portObj.WriteLine($Cmd)
        Start-Sleep -Milliseconds $WaitMs

        # Read response
        $response = ""
        $deadline = [DateTime]::Now.AddMilliseconds($TimeoutMs)
        while ([DateTime]::Now -lt $deadline) {
            try {
                $chunk = $portObj.ReadExisting()
                if ($chunk) {
                    $response += $chunk
                    # Keep reading while data is coming
                    Start-Sleep -Milliseconds 100
                } else {
                    Start-Sleep -Milliseconds 50
                }
            } catch {
                break
            }
        }

        Write-Host "  Response:"
        $response -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

        # Check keywords
        $allFound = $true
        foreach ($kw in $ExpectedKeywords) {
            if ($response -match [regex]::Escape($kw)) {
                Write-Host "  [OK] Found: '$kw'" -ForegroundColor Green
            } else {
                Write-Host "  [MISS] Not found: '$kw'" -ForegroundColor Red
                $allFound = $false
            }
        }

        if ($allFound) {
            Write-Host "  >> PASS" -ForegroundColor Green
            $script:passed++
            $script:testResults += [PSCustomObject]@{Port=$Name; Test=$TestName; Result="PASS"; Detail=""}
        } else {
            Write-Host "  >> FAIL" -ForegroundColor Red
            $script:failed++
            $script:testResults += [PSCustomObject]@{Port=$Name; Test=$TestName; Result="FAIL"; Detail="Missing keywords"}
        }
    }

    # ==== Test Cases ====

    # Test 1: Check boot prompt
    InvokeShellTest -Cmd "" -TestName "BootPrompt" -ExpectedKeywords @("dpiny-RTK", "help") -WaitMs 2000

    # Test 2: help command
    InvokeShellTest -Cmd "help" -TestName "HelpCommand" -ExpectedKeywords @("help", "status", "config", "save", "reset", "baud", "usb", "version")

    # Test 3: version command
    InvokeShellTest -Cmd "version" -TestName "VersionCommand" -ExpectedKeywords @("dpiny-RTK", "STM32F407", "UM982", "FreeRTOS")

    # Test 4: usb command (VCP should show Connected=YES)
    if ($Name -eq "VCP") {
        InvokeShellTest -Cmd "usb" -TestName "UsbCommand" -ExpectedKeywords @("USB", "Connected", "YES")
    } else {
        InvokeShellTest -Cmd "usb" -TestName "UsbCommand" -ExpectedKeywords @("USB", "Connected")
    }

    # Test 5: status command
    InvokeShellTest -Cmd "status" -TestName "StatusCommand" -ExpectedKeywords @("System Status", "Passthrough", "GNSS", "Watchdog")

    # Test 6: config command
    InvokeShellTest -Cmd "config" -TestName "ConfigCommand" -ExpectedKeywords @("Configuration", "UART1", "UART4", "GNSS")

    # Test 7: unknown command
    InvokeShellTest -Cmd "blah" -TestName "UnknownCommand" -ExpectedKeywords @("Unknown")

    # Test 8: prompt echo (send empty line)
    InvokeShellTest -Cmd "" -TestName "PromptEcho" -ExpectedKeywords @(">")

    $portObj.Close()
    Write-Host "[INFO] Port closed" -ForegroundColor Green
}

# ====== Run Tests ======
Write-Host "`n" -NoNewline
Write-Host "########################################" -ForegroundColor Magenta
Write-Host "# dpiny-RTK Shell & VCP Test Suite     #" -ForegroundColor Magenta
Write-Host "########################################" -ForegroundColor Magenta

# Need to wait for the board to fully boot after flash
Write-Host "`nWaiting 3 seconds for board to boot..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Test VCP first (COM4)
Test-Port -Port $VcpPort -Name "VCP"

# Short delay between tests
Start-Sleep -Seconds 1

# Test USART3 (COM11)
Test-Port -Port $UartPort -Name "USART3"

# ====== Summary ======
Write-Host "`n" -NoNewline
Write-Host "########################################" -ForegroundColor Magenta
Write-Host "# Test Summary                          #" -ForegroundColor Magenta
Write-Host "########################################" -ForegroundColor Magenta

$testResults | Format-Table -AutoSize

Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
