# Auto-commit script for git repository
# This script adds all changes and commits them with a timestamp

# Change to the repository directory
Set-Location "C:\Users\Julius\Meine Ablage\Studium\Hiwi\Tetrix\Publications\Control"

# Check if there are any changes to commit
$status = git status --porcelain
if ($status) {
    # Add all changes
    git add .
    
    # Create commit message with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMessage = "Auto-commit: $timestamp"
    
    # Commit the changes
    git commit -m $commitMessage
    
    # Optional: Push to remote repository (uncomment the line below if you want to auto-push)
    # git push origin master
    
    Write-Host "Auto-commit completed at $timestamp"
} else {
    Write-Host "No changes to commit at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}