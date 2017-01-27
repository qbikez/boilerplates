[cmdletbinding(supportsshouldprocess)]
param(
    [Parameter(mandatory=$true)]$src, 
    [Parameter(mandatory=$true)]$dest, 
    $desttype = "hg", 
    $filemap = "filemap.txt", 
    $branchmap = "branchmap.txt", 
    $srcbranch = $null, 
    [switch][bool] $force = $false, 
    [switch][bool] $append = $false, 
    $startrev = $null,   
    [switch][bool] $ignorerrors)

pushd
cd $PSScriptRoot

try {

import-module require
req pathutils
req deployment
req process

function generate-filemapentry($src, $srcpath, $destpath, $action = "include") {
    $map = @()
    if ($srcpath.startswith("r:") -or $srcpath.startswith("r:!")) {
            
            if ($srcpath.startswith("r:!")) {
                throw "path r:! not implemented"
            }
            elseif ($srcpath.startswith("r:")) {
                $srcpath = $srcpath.substring("r:".Length)
                $isdir = $false
                if ($srcpath.endswith("/")) { 
                    $isdir = $true
                    $srcpath = $srcpath.trimend("/")
                }
               # $srcpath = $srcpath -replace "/","\"
                Get-Listing -Path $src -Excludes @(".hg/","dnx-packages/","node_modules/","packages/","bin/","obj/","testresults/") -Recurse `
                  -dirs:$isdir -include $srcpath | % {
                    $path = get-relativepath $src $_.FullName
                    $map += "$action ""$($path.replace("\","/"))"""
                }
            }
    }
    elseif ($srcpath.startswith("sln:")) {
        $path = $srcpath.substring("sln:".Length)
        $sln = (get-item (join-path $src $path)).FullName
        $items = & "$psscriptroot\get-sln-items.ps1" -sln $sln
        $items = $items | % { get-relativepath -from $src -to $_ } | % { "$action $($_.replace("\","/"))" }
        return @($items) + @("$action $path")

    }
    else {
        $map += "$action ""$($srcpath.replace("\","/"))"""
    }
    return $map
}

function filter-filemap ($map) {
    $toremove = @()
    $newmap = @()
 #   foreach($entry in $map) {
 #       $list += $entry    
 #   }
   # $map = $list
    $hashmap = @{}
    for($i = $map.Length - 1; $i -ge 0; $i--) {
        $entry = $map[$i]
        $space = $entry.indexof(" ")
        $path = $entry.substring($space+1)
        if ($hashmap[$path] -eq $null) {
            $hashmap[$path] = @($i)
            $newmap += $entry
        } else {
            # $path was already found. remove all other entries
            $toremove += $i
        }
    }

    # remove from the end to avoid index shift
#    for($i = $toremove.length-1; $i -ge 0; $i--) {
#        write-host "removing duplicate item '$($map[$i])' at pos $i"
#    }

    [Array]::Reverse($newmap)
    return $newmap
}

function generate-branchmapentry($src, $srcbranch, $destbranch, $branches) {    
    pushd
    try {
        if ($srcbranch -eq "*") {
            #$branches = $branches | % { $_.Split(" ")[0] }
            $map = $branches | % { "$_ $destbranch" }
            return $map
        }
        elseif ($srcbranch.startswith("r:") -or $srcbranch.startswith("r:!")) {
            $map = @()
            if ($srcbranch.startswith("r:!")) {
                $srcbranch = $srcbranch.substring("r:!".Length)
                $branches | % {
                    if ($_ -notmatch $srcbranch) {
                        if ($_ -match "\s") { $_ = """$_""" }
                        $map += "$_ $destbranch"
                    }
                }
            }
            elseif ($srcbranch.startswith("r:")) {
                $srcbranch = $srcbranch.substring("r:".Length)
                $branches | % {
                    if ($_ -match $srcbranch) {
                    if ($_ -match "\s") { $_ = """$_""" }
                        $map += @("$_ $destbranch")
                    }
                }
            }
            return $map
        } 
        else {
            return "$srcbranch $destbranch"
        }
    }
    finally {
        popd
    }
}

if ($dest.endswith(".git")) { 
    $desttype = "git"
    $dest = $dest.Replace(".git",".hg")
}

if ((test-path $dest) -and $force) {
    invoke cmd /c rmdir $dest /S /Q
}
if (!(test-path $dest) -or $append)
 {
    if ($srcbranch -ne $null) {
        pushd 
        try {
            cd $src
            hg update $srcbranch 
            if ($lastexitcode -ne 0) {
                throw "failed to update to branch $srcbranch in $src"
            }
        } finally {
            popd
        }
    }
    #$content = $includePaths | % {
    #    "include ""$_"""
    #}
    #$content | Out-File $filemap -Encoding ascii
    write-host "generating branchmap"
    copy-item $branchmap "branchmap.gen.txt"
    $branchmap = "branchmap.gen.txt"
    $bmap = get-content $branchmap
    pushd 
    try {
        cd $src
        $branches = hg branches -c
        $branches = $branches | % {
            $null = $_ -match "(?<name>.*?)\s+[0-9]+:"
            $matches["name"]
        }
    } finally {
        popd
    }
    $bmap = $bmap | % {
        if ($_ -match "(?<src>.*) (?<dst>.*)") {
            $generated = generate-branchmapentry $src $Matches["src"] $Matches["dst"] $branches
            $generated
        }
        else {
            $_
        }
    }

    $bmap | out-file $branchmap -Encoding ascii

 

    $processfilemap = $true
    if (test-path "filemap.gen.txt") {
        $gen = get-item "filemap.gen.txt"
        $org = get-item $filemap
        if ($org.LastWriteTimeUtc -le $gen.LastWriteTimeUtc) {
            $processfilemap = $false
        }
        
    }
    if ($processfilemap) {
        write-host "generating filemap"
        #copy-item $filemap "filemap.gen.txt"
        $fmap = get-content $filemap
        $filemap = "filemap.gen.txt"        
        pushd 
        $fmap = $fmap| % {
            if ($_ -match "(?<action>include|exclude) (?<src>.*)") {
                $generated = generate-filemapentry $src $Matches["src"] -action $Matches["action"] 
                $generated
            }
            else {
                $_
            }
        }
        $fmap = filter-filemap $fmap

        $fmap | out-file $filemap -Encoding ascii
    } else {
        $filemap = "filemap.gen.txt"
    }

    write-host "converting"

    $p = @(
        "--config","extensions.hgext.convert="
        "--dest-type","hg"
        "--filemap",(get-item $filemap).FullName
        "--branchmap",(get-item $branchmap).FullName
        "--verbose"
        "--full"
    )
    if ($startrev -ne $null) {
        $p += "--config","convert.hg.startrev=$startrev"
    }
    if ($ignorerrors){
        $p += "--config","convert.hg.ignoreerrors=True"
    }

    $p += $src,$dest


    write-host "executing:"
    Write-Host "hg convert $p"

    $converted = $false
    if ($PSCmdlet.ShouldProcess("running hg convert")) {        
        invoke hg convert @p -verbose
        $converted = $true
    }

    push-location
    try {
        if (test-path $dest) {
            cd $dest
            invoke hg sum
            invoke hg status
            invoke hg log
        }
    } finally {
        pop-location
    }
} else {
    write-warning "$dest already exists. not doing hg convert"
}

if ($desttype -eq "git") {    
     .\hg2git.ps1 -src $dest -force:$force

}


}
finally {
popd
}