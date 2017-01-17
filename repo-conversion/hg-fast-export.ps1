[cmdletbinding(supportsshouldprocess)]
param(
    [Parameter(mandatory=$true)]$src, 
    [Parameter(mandatory=$true)]$dest, 
    $desttype = "git", 
    [switch][bool]$force = $true,
    $fastexport = $null
)

ipmo require
req process

if ($fastexpor -eq $null) { $fastexport = "$psscriptroot\fast-export\hg-fast-export.py" }

if ((test-path $dest) -and $force) {
    remove-item $dest -Recurse -Force
}

if (!(test-path $dest))
{
    & "$psscriptroot\hg-convert.ps1" @PSBoundParameters
}

if ($desttype -eq "git") {

    # export
    $PYTHON = "python"
    $GIT_DIR = ".git"
    

       push-location
    try {
        $gitdst = "$dest.git"
        if (test-path $gitdst) { remove-item $gitdst -Recurse -Force }
        $null = new-item $gitdst -type directory
        cd $gitdst
        git init

        #python hg-fast-export.py  -r src\repo.h --marks .git\marks.txt --mapping .git\mapping.txt --heads .git\heads.txt --status .git\status.txt
         # python hg-fast-export.py  -r src\repo.hg --marks .git\marks.txt --mapping .git\mapping.txt --heads .git\heads.txt --status .\git\status.txt
<#    $result = & $PYTHON $fastexport --repo $dest `
          --marks "$GIT_DIR/git-marks.txt" `
          --mapping "$GIT_DIR/git-mapping.txt" `
          --heads "$GIT_DIR/git-heads.txt" `
          --status "$GIT_DIR/git-status.txt"
    $resultpath = "$GIT_DIR/fast-import.txt"
    $result | Out-File $resultpath -Encoding ascii
    $resultfile = gi $resultpath
 
        $result | & git fast-import --export-marks="$GIT_DIR/git-export-marks.txt"#>

        invoke -useShellExecute python @(
            "$fastexport" 
            "-r","$dest"
            "--marks",".git\marks.txt"
            "--mapping",".git\mapping.txt"
            "--heads",".git\heads.txt"
            "--status",".git\status.txt"
            "--force"
            "> .git\fast-export.txt"            
        invoke -useShellExecute git @(
             "fast-import"
             "< .git\fast-export.txt"
            )


        git log
    } finally {
        pop-location
    }

}