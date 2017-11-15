param($path)

ipmo require
if (gmo eps) { rmo eps }

ipmo "$psscriptroot\.deps\eps\eps\eps.psd1" -ErrorAction stop


if ($path -ne $null) {
    $items = @(get-item $path)
} else {
    $items = gci . -Filter "*.mdt" -Recurse
}
$properties = . "$PSScriptRoot\properties.config.ps1"

$helpers = @{
    ScriptLink = [scriptblock]{ param($repo, $path) 
         return "[``$path``]($($repo.url)/file/default/$path)"
    }
}


foreach($it in $items) {
    write-verbose "processing $($it.name)" -verbose
    $r = Invoke-EpsTemplate -Path $it.fullname -Binding $properties -Helpers $helpers  -ErrorAction Stop
    $outfile = $it.fullname.Replace(".mdt",".md")
    $r | Out-File $outfile -Encoding utf8
}