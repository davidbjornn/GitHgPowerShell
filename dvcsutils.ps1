
# Custom Prompt based on
# Mark Embling (http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration)

# and TabCompletion based on
# Jeremy Skinner (http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/)

function isCurrentDirectoryARepository($type) {
    if ((Test-Path $type) -eq $TRUE) {
        return $TRUE
    }
    
    # Test within parent dirs
    $checkIn = (Get-Item .).parent
    while ($checkIn -ne $NULL) {
        $pathToTest = $checkIn.fullname + '/' + $type;
        if ((Test-Path $pathToTest) -eq $TRUE) {
            return $TRUE
        } else {
            $checkIn = $checkIn.parent
        }
    }    
    return $FALSE
}

# Get the current branch
function hgBranchName {
    return hg branch
}

function gitBranchName {
    $currentBranch = ''
    git branch | foreach {
        if ($_ -match "^\* (.*)") {
            $currentBranch += $matches[1]
        }
    }
    return $currentBranch
}

# Extracts status details about the repo
function hgStatus {
    $untracked = $FALSE
    $missing = $FALSE
    $added = 0
    $modified = 0
    $deleted = 0
    $ahead = $FALSE
    $aheadCount = 0
    
    $output = hg status
    
    $branch = hgBranchName
    
    $output | foreach {
        if ($_ -match "R ") {
            $deleted += 1
        }
        elseif ($_ -match "M ") {
            $modified += 1
        }
        elseif ($_ -match "A ") {
            $added += 1
        }
        elseif ($_ -match "\? ") {
            $untracked = $TRUE
        }
        elseif ($_ -match "! ") {
            $missing = $TRUE
        }
    }
    
    return @{"untracked" = $untracked;
             "added" = $added;
             "modified" = $modified;
             "deleted" = $deleted;
             "ahead" = $ahead;
             "aheadCount" = $aheadCount;
             "branch" = $branch;
             "missing" = $missing}
}

function gitStatus {
    $untracked = $FALSE
    $added = 0
    $modified = 0
    $deleted = 0
    $ahead = $FALSE
    $aheadCount = 0
    $missing = $FALSE
    $output = git status
    
    $branchbits = $output[0].Split(' ')
    $branch = $branchbits[$branchbits.length - 1]
    
    $output | foreach {
        if ($_ -match "^\#.*origin/.*' by (\d+) commit.*") {
            $aheadCount = $matches[1]
            $ahead = $TRUE
        }
        elseif ($_ -match "deleted:") {
            $deleted += 1
        }
        elseif (($_ -match "modified:") -or ($_ -match "renamed:")) {
            $modified += 1
        }
        elseif ($_ -match "new file:") {
            $added += 1
        }
        elseif ($_ -match "Untracked files:") {
            $untracked = $TRUE
        }
    }
    
    return @{"untracked" = $untracked;
             "added" = $added;
             "modified" = $modified;
             "deleted" = $deleted;
             "ahead" = $ahead;
             "aheadCount" = $aheadCount;
             "branch" = $branch;
             "missing" = $missing}
}

function writeDVCSStatus($status) {
        $currentBranch=$status["branch"]
        Write-Host(' [') -nonewline -foregroundcolor Yellow
        if (($status["ahead"] -eq $FALSE) -and ($status["missing"] -eq $FALSE) -and ($status["untracked"] -eq $FALSE)) {
            # We are not ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Cyan
        } else {
            # We are ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Red
        }
        Write-Host(' +' + $status["added"]) -nonewline -foregroundcolor Yellow
        Write-Host(' ~' + $status["modified"]) -nonewline -foregroundcolor Yellow
        Write-Host(' -' + $status["deleted"]) -nonewline -foregroundcolor Yellow
        Write-Host(']') -nonewline -foregroundcolor Yellow 
}

function getCommands($output, $expression, $filter)
{
  $cmdList = @()
  foreach($line in $output) {
    if($line -match $expression) {
      $cmd = $matches[1]
      if($filter -and $cmd.StartsWith($filter)) {
        $cmdList += $cmd.Trim()
      }
      elseif(-not $filter) {
        $cmdList += $cmd.Trim()
      }
    }
  } 
  $cmdList | sort
}

function hgCommands($filter) {
    $output = hg help
    getCommands $output '^ (\S+) (.*)' $filter

}
function gitCommands($filter) {
   $output = git help
   getCommands $output '^   (\S+) (.*)' $filter
}

function gitRemotes($filter) {
  if($filter) {
    git remote | where { $_.StartsWith($filter) }
  }
  else {
    git remote
  }
}

function hgRemotes($filter) {
   hg paths | foreach { 
      if($_ -match "^(.*) = .*") { 
        if($filter -and $matches[1].StartsWith($filter)) {
          $matches[1].Trim()
        }
        elseif(-not $filter) {
          $matches[1].Trim()
        }
      } 
   }
}
 
function gitLocalBranches($filter) {
   git branch | foreach { 
      if($_ -match "^\*?\s*(.*)") { 
        if($filter -and $matches[1].StartsWith($filter)) {
          $matches[1]
        }
        elseif(-not $filter) {
          $matches[1]
        }
      } 
   }
}


function hgLocalBranches($filter) {
   hg branches | foreach { 
      if($_ -match "^(.*) .*") { 
        if($filter -and $matches[1].StartsWith($filter)) {
          $matches[1].Trim()
        }
        elseif(-not $filter) {
          $matches[1].Trim()
        }
      } 
   }
}

function gitTabExpansion($lastBlock) {
     switch -regex ($lastBlock) {
 
        #Handles git branch -x -y -z <branch name>
        'git branch -(d|D) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git checkout <branch name>
        #handles git merge <brancj name>
        'git (checkhout|merge) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git <cmd>
        #handles git help <cmd>
        'git (help )?(\S*)$' {      
          gitCommands($matches[2])
        }
 
        #handles git push remote <branch>
        #handles git pull remote <branch>
        'git (push|pull) (\S+) (\S*)$' {
          gitLocalBranches($matches[3])
        }
 
        #handles git pull <remote>
        #handles git push <remote>
        'git (push|pull) (\S*)$' {
          gitRemotes($matches[2])
        }
    }	
}

function hgTabExpansion($lastBlock) {
     switch -regex ($lastBlock) {
 
        #Handles git branch -x -y -z <branch name>
        'hg branch (\S*)$' {
          hgLocalBranches($matches[2])
        }
 
        #handles git checkout <branch name>
        #handles git merge <brancj name>
        'hg (update|merge) (\S*)$' {
          hgLocalBranches($matches[2])
        }
 
        #handles git <cmd>
        #handles git help <cmd>
        'hg (help )?(\S*)$' {      
          hgCommands($matches[2])
        }
 
        #handles git push remote <branch>
        #handles git pull remote <branch>
        'hg (push|pull) (\S+) (\S*)$' {
          hgLocalBranches($matches[3])
        }
 
        #handles git pull <remote>
        #handles git push <remote>
        'hg (push|pull) (\S*)$' {
          hgRemotes($matches[2])
        }
    }	
}