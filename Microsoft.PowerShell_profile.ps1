# Custom Prompt based on
# Mark Embling (http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration)

# and TabCompletion based on
# Jeremy Skinner (http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/)

. (Resolve-Path ~/Documents/WindowsPowershell/dvcsutils.ps1)
 
function prompt {
	$path = ""
	$pathbits = ([string]$pwd).split("\", [System.StringSplitOptions]::RemoveEmptyEntries)
	if($pathbits.length -eq 1) {
		$path = $pathbits[0] + "\"
	} else {
		$path = $pathbits[$pathbits.length - 1]
	}
	$userLocation = $path
	$titleLocation = $env:username + '@' + [System.Environment]::MachineName + ' ' + $pwd
    
	$host.UI.RawUi.WindowTitle = $titleLocation
    Write-Host($userLocation) -nonewline -foregroundcolor Green 
    
    if (isCurrentDirectoryARepository(".git")) {
    	$host.UI.RawUi.WindowTitle = $titleLocation + ' (Git Repository)';
        $status = gitStatus
        writeDVCSStatus($status);
        
    } elseif (isCurrentDirectoryARepository(".hg")) {
    	$host.UI.RawUi.WindowTitle = $titleLocation + ' (Mercurial Repository)';
        $status = hgStatus
        writeDVCSStatus($status);
    }
    
	Write-Host('>') -nonewline -foregroundcolor Green
	return " "
}


function TabExpansion($line, $lastWord) {
  $LineBlocks = [regex]::Split($line, '[|;]')
  $lastBlock = $LineBlocks[-1] 
 
  switch -regex ($lastBlock) {
    'git (.*)' { gitTabExpansion($lastBlock) }
    'hg (.*)' { hgTabExpansion($lastBlock) }
  }
}
