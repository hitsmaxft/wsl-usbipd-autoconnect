#!/usr/bin/env powershell.exe

# auto gen by chatgpt4

param([string]$vid_pid)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

$firstOutput = 1

while ($true) {
    # STEP0
    $usbipdListOutput = usbipd.exe list

    # Find the line number where "Persisted:" starts
    $lineOfPersisted = ($usbipdListOutput | Select-String "Persisted:" -AllMatches).LineNumber

    # Get all lines before "Persisted:"
    $relevantOutputLines = $usbipdListOutput -split "`n" | Select-Object -First ($lineOfPersisted - 1)
    # Join the lines back to a single string to continue with the existing processing
    $relevantOutput = $relevantOutputLines -join "`n"

    # Write-Host $relevantOutput
    # Check if the VID:PID exists in the list
    $deviceLine = ($relevantOutput -split "\n") | Where-Object { $_ -match "$vid_pid" }

    if (-not $deviceLine) {
        # STEP3 - Report error
        if ($FIrstOutput) {
            Write-Host -NoNewline "device ${vid_pid} not found"
            $firstOutput =  0
        } else {
            Write-Host -NoNewline "."
        }
        Start-Sleep -Seconds 1
        continue
    } else {
            Write-Host "\n"
            $firstOutput = 1
    }

    # Parsing the variables
    $parts = $deviceLine -split "\s{2,}"

    # debug output
    # foreach ($part in $parts) {
    #     Write-Output "["$part"]"
    # }

    $busId = $parts[0]
    $vidPid = $parts[1]
    $device = $parts[2]
    $state = $parts[-1].TrimStart()

    # Check the status of the device
    switch ($state) {
        "Attached" {
            # STEP2 - Device is attached, sleep for 5s
            Start-Sleep -Seconds 5
            break;
        }
        default {
            # STEP1 - Device is shared, try to attach
            Write-Host "state is "$state
            try {
                Write-Host "Connecting"
                sudo usbipd.exe wsl attach --busid $busId
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "An error occurred while trying to attach the device."
            }
            #Write-Host "status unknown：$state"
            Start-Sleep -Seconds 3
            break;
        }
    }

    Start-Sleep -Seconds 1
}
