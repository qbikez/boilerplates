param ([Parameter(Mandatory=$true)]$sln)

$content = get-content $sln

$csprojlines = $content | ? { $_ -match "\.csproj" -or $_ -match "\.xproj" }

$dir = split-path -parent $sln

$csprojs = $csprojlines | % {
    if ($_ -match '^.* = "[^"]*", "(?<csprojpath>[^"]*)"') {
        return  $Matches["csprojpath"]
    }
}

$csprojs = $csprojs | % {
    return (join-path $dir $_)
} | % {
    return (get-item $_).fullname
} | % {
    return split-path -parent $_
}


$includes = $csprojs | % {
    return "$($_.replace("\","/").substring("c:/legimi/legimi.default/".length))"
}



pushd

try {
cd $dir

}
finally {
popd
}

return $includes