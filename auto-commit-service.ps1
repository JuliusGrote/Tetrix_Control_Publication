# Continuous auto-commit service
# This script runs continuously and commits every 3 days

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Service
)

$repoPath = "C:\Users\Julius\Meine Ablage\Studium\Hiwi\Tetrix\Publications\Control"
$logFile = Join-Path $repoPath "auto-commit.log"
$intervalDays = 3

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $Message"
}

function Perform-AutoCommit {
    Set-Location $repoPath
    
    $status = git status --porcelain
    if ($status) {
        git add .
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $commitMessage = "Auto-commit: $timestamp"
        git commit -m $commitMessage
        Write-Log "Auto-commit completed: $commitMessage"
        
        # Uncomment to auto-push
        # git push origin master
        # Write-Log "Changes pushed to remote"
    } else {
        Write-Log "No changes to commit"
    }
}

if ($Service) {
    Write-Log "Starting auto-commit service (every $intervalDays days)"
    
    while ($true) {
        try {
            Perform-AutoCommit
            $nextRun = (Get-Date).AddDays($intervalDays)
            Write-Log "Next auto-commit scheduled for: $nextRun"
            
            # Sleep for 3 days (in seconds: 3 * 24 * 60 * 60 = 259200)
            Start-Sleep -Seconds 259200
        }
        catch {
            Write-Log "Error occurred: $($_.Exception.Message)"
            Start-Sleep -Seconds 3600  # Wait 1 hour before retrying
        }
    }
}

if ($Install) {
    Write-Log "Installing auto-commit service..."
    # You can create a Windows service here or use Task Scheduler
    Write-Host "Please set up Windows Task Scheduler manually or run with -Service parameter"
}

# Default: run once
if (-not $Service -and -not $Install -and -not $Uninstall) {
    Perform-AutoCommit
}