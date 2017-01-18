param(
    [Parameter(Mandatory=$true)]$src,
    [Parameter(Mandatory=$false)]$python = "python", 
    [Parameter(Mandatory=$false)]$fastexport = "fast-export",
    [switch][bool] $force = $false
)

pushd
try {

    ipmo require
    req process

    $srcfull = (get-item $src).FullName

    cd $PSScriptRoot

    if (!(test-path $fastexport)) { 
        & git clone https://github.com/frej/fast-export $fastexport 2>&1 
    }
    $fastexport = (get-item $fastexport).FullName

    $dest = $srcfull.Replace(".hg",".git")
    if (!$dest.Contains("git")) { $dest = $dest + ".git" }

    if (test-path $dest) {
        if ($force) {
            write-warning "-force specified. removing $dest"
            cmd /c rmdir /S /Q $dest
        }
        else { 
            write-warning "$dest already exists. not doing anything"
            return
        }
    }
    mkdir $dest
    cd $dest
    git init .
    try {
    if (test-path git-fast-import.src) {
        rm git-fast-import.src
    }
    invoke -useshellexecute $python "$fastexport\hg-fast-export.py -r $src --marks=marks.txt --mapping=mapping.txt --heads=heads.txt --status=status.txt > git-fast-import.src" -Verbose
    } catch {
        if (test-path git-fast-import.src) {
            $msg = get-content git-fast-import.src
            throw $msg
        } else {
            throw
        }
    }
    
    invoke -useshellexecute git "fast-import --export-marks=marks.txt.tmp < git-fast-import.src" -Verbose
    
} finally {
    popd
}