param($path) 

ipmo require
req crayon

$linkregex = "\[(?<label>.*?)\]\((?<url>http.*?)\)"

if ($path -ne $null) {
    if ((get-item $path).psiscontainer) {
        $files = get-childitem $path -filter "*.md" -Recurse | select -ExpandProperty FullName
    }
    else {
        $files = @($path)
    }
} else {
    $files = get-childitem -filter "*.md" -Recurse | select -ExpandProperty FullName
}

foreach($file in @($files)) {
    log-verbose "checking file '$file'" -Verbose
    get-content $file | % {
        if ($_ -match $linkregex) {
            $url = $matches["url"] 
            log-verbose "testing url '$url'" -Verbose
            $r = Invoke-WebRequest $url -Verbose -UseBasicParsing -Method Head
            
        }
    }
}
