# Google Drive Auto-commit Script
# This script is designed to work with Google Drive File Stream/Backup & Sync
# It handles the specific behaviors of Google Drive syncing

# Configuration
$repoPath = "C:\Users\Julius\Meine Ablage\Studium\Hiwi\Tetrix\Publications\Control"
$logFile = Join-Path $repoPath ".auto-commit.log"
$lockFile = Join-Path $repoPath ".auto-commit.lock"

function Write-AutoCommitLog {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Test-GoogleDriveSync {
    # Check if Google Drive is actively syncing
    $driveProcesses = Get-Process | Where-Object { $_.ProcessName -like "*GoogleDrive*" -or $_.ProcessName -like "*GoogleDriveFS*" }
    return $driveProcesses.Count -gt 0
}

function Wait-ForGoogleDriveSync {
    # Wait for Google Drive to finish syncing
    $maxWaitMinutes = 10
    $waitStart = Get-Date
    
    while ((Get-Date) -lt $waitStart.AddMinutes($maxWaitMinutes)) {
        # Check if any files are currently being modified
        $recentFiles = Get-ChildItem -Path $repoPath -Recurse -File | 
                      Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-2) }
        
        if ($recentFiles.Count -eq 0) {
            Write-AutoCommitLog "Google Drive appears to be synced"
            return $true
        }
        
        Write-AutoCommitLog "Waiting for Google Drive sync to complete..."
        Start-Sleep -Seconds 30
    }
    
    Write-AutoCommitLog "Timeout waiting for Google Drive sync"
    return $false
}

function Invoke-SafeAutoCommit {
    # Check if another instance is running
    if (Test-Path $lockFile) {
        $lockAge = (Get-Date) - (Get-Item $lockFile).LastWriteTime
        if ($lockAge.TotalMinutes -lt 30) {
            Write-AutoCommitLog "Another auto-commit instance is running"
            return
        } else {
            Remove-Item $lockFile -Force
        }
    }
    
    # Create lock file
    "Auto-commit started at $(Get-Date)" | Out-File -FilePath $lockFile
    
    try {
        Set-Location $repoPath
        
        # Wait for Google Drive to sync
        if (-not (Wait-ForGoogleDriveSync)) {
            Write-AutoCommitLog "Proceeding despite sync timeout"
        }
        
        # Check for changes
        $status = git status --porcelain 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-AutoCommitLog "Git status failed - repository may not be initialized"
            return
        }
        
        if ($status) {
            # Add all changes
            git add . 2>&1 | Out-String | Write-AutoCommitLog
            
            # Create commit with detailed message
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $changedFiles = ($status | Measure-Object).Count
            $commitMessage = "Auto-commit: $timestamp ($changedFiles files changed)"
            
            git commit -m $commitMessage 2>&1 | Out-String | Write-AutoCommitLog
            
            if ($LASTEXITCODE -eq 0) {
                Write-AutoCommitLog "Commit successful: $commitMessage"
                
                # Optional: Push to remote (uncomment if needed)
                # git push origin HEAD 2>&1 | Out-String | Write-AutoCommitLog
                # Write-AutoCommitLog "Push completed"
            } else {
                Write-AutoCommitLog "Commit failed"
            }
        } else {
            Write-AutoCommitLog "No changes to commit"
        }
    }
    catch {
        Write-AutoCommitLog "Error: $($_.Exception.Message)"
    }
    finally {
        # Remove lock file
        if (Test-Path $lockFile) {
            Remove-Item $lockFile -Force
        }
    }
}

# Run the auto-commit
Invoke-SafeAutoCommit