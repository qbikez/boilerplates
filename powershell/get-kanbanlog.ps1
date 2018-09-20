param($from = "auto", $board, [switch][bool] $removeBreaks = $true, $maxBreak = 20, $delimiter = $null, [switch][bool] $clearCredentials) 

ipmo require
req crayon
req pathutils
req cache

if ($delimiter -eq $null) {
    $delimiter = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ListSeparator
}

function get-kanbanlog {
    [cmdletbinding()]
    param( $from, $board, [switch][bool] $removeBreaks = $true, $maxBreak = 20, $delimiter = $null, [switch][bool] $clearCredentials) 

    cd $PSScriptRoot

    $fromD = switch($from) {
        {  $_ -in "month","m",$null }  { (get-date).AddDays(-30) }
        {  $_ -in "week","w",$null }  { (get-date).AddDays(-7) }
        { $_ -in "today","t" } {  (get-date).Date }
        {  $_ -in "yesterday","y" } { (get-date).Date.AddDays(-1) }
        default { 
            try {
                if ($from -is [datetime] -or $from -is [System.DateTimeOffset]) {
                    $from
                }
                else {
                    [datetime]::Parse($from)
                }                
            } catch {
                throw "could not parse 'From' date: $from"
            }
         }
    }
    $fromD = new-object DateTimeOffset (new-object DateTime $fromD.Year,$fromD.Month,$fromD.Day)
    
    $from = $fromD.ToString("yyyy-MM-ddTHH:mm:ss.sss") + "Z";# + "+$($fromD.Offset.Hours.ToString("00")):$($fromD.Offset.Minutes.ToString("00"))"  # "2015-10-22T22:00:00.000Z"

    log-progress "getting kanbanflow log from $fromD ($from)"
    $cred = get-credentialscached -message "kanbanflow" -container "kanbanflow.com" -reset:$clearCredentials
    $user = $cred.UserName
    $pass = $cred.GetNetworkCredential().Password


    $url = "https://kanbanflow.com/login"

    $s = $null
    $r = Invoke-WebRequest $url -Method Post -Body "email=$user&password=$pass" -SessionVariable "s" -UseBasicParsing

    $url = "https://kanbanflow.com/board/$board" 
    $r = Invoke-WebRequest $url -WebSession $s -UseBasicParsing
    #$r

    $url = "https://kanbanflow.com/work-timer/log-data?startTimestamp=$from&boardId=$board" 
    #$url = "https://kanbanflow.com/work-timer/log-data?startTimestamp=2015-10-09T22:00:00.000Z&boardId=b2bc0281ee064a0e547ae2dc5b0e65bc"
    # https://kanbanflow.com/work-timer/log-data?startTimestamp=2017-08-24T22%3A00%3A00.000Z&boardId=b2bc0281ee064a0e547ae2dc5b0e65bc
    
    $r = Invoke-WebRequest $url -WebSession $s -UseBasicParsing
    try {
    $w = $r.Content | ConvertFrom-Json
    } catch {
        throw "failed to parse content from '$url'"
    }
    $result = @()

    $start = [datetimeoffset]::MinValue
    $end = [datetimeoffset]::MinValue

    $entries = @($w.workEntries) + @($w.manualTimeEntries)
    $entries = $entries | sort startTimestampLocal
    foreach($entry in $entries) {
        $start = $entry.startTimestampLocal
        $start = [datetimeoffset]::Parse($start)
        if ($start - $end -lt [timespan]::FromMinutes($maxBreak) -and $removeBreaks) {
            $start = $end
        }
        $actions = $entry.actions
        $sub = @()
        if ($actions -ne $null) {
            foreach($a in $actions) {
                $end = $a.end.TimestampLocal
                $end = [datetimeoffset]::Parse($end)
                $task = $a.taskName
                $project = ""
                $p = [ordered]@{ 
                    from = $start
                    to = $end
                    date = $start.Date.ToString("yyyy-MM-dd")
                    fromTime = $start.ToString("HH:mm")
                    toTime = $end.ToString("HH:mm")
                    task = $task
                    project = $project
                }
                $s = new-object -type pscustomobject -Property $p
                $start = $end

                $sub += $s
            }
        }
        else {
            $end = $entry.endTimestampLocal
            $end = [datetimeoffset]::Parse($end)
            $task = $entry.taskName
            $project = ""

            $p = [ordered]@{ 
                from = $start
                to = $end
                date = $start.Date.ToString("yyyy-MM-dd")
                fromTime = $start.ToString("HH:mm")
                toTime = $end.ToString("HH:mm")
                task = $task
                project = $project
            }
            $s = new-object -type pscustomobject -Property $p
            $start = $end

            $sub += $s
        }
        $result += $sub
    }

    log-progress "done" -percentComplete 100

    return $result
}

pushd
try {
    $bound = $PSBoundParameters
    $c = import-cache -container "kanban-log"

    if ($board -eq $null) {
        if ($c -ne $null) {
            $board = $c.board
        } 
        if ($board -eq $null) {
            $board = read-host -Prompt "Board id"
        }
        
        $bound["board"] = $board
    }    

    if ($from -eq "auto") {
        if ($c -ne $null) {
            write-verbose "last log timestamp: '$($c.timestamp.DateTime)'" -Verbose
            $from = [DateTime]::Parse($c.timestamp.DateTime)
        } else {
            $from = "month"
        }
        if ($from -is [datetime] -and ((get-date) - $from).totaldays -gt 31) {
            $from = "week"
        }
        $bound["from"] = $from
    }

    $timesheetUrl = $null
    if ($c -ne $null) {
        $timesheetUrl = $c.timesheetUrl
    }

    $outfile = "data/kanban-log.csv" 
    if (!(Test-Path "data")) { $null = mkdir "data" }
    $kblog = get-kanbanlog @bound
    $kblog | Export-Csv -Path $outfile -NoTypeInformation -Encoding UTF8 -Delimiter $delimiter -Force 
    $suffix = $from
    if ($suffix -is [DateTime]) {
        $suffix = "-from-$($from.ToString("yyyy-MM-dd"))"
    }
    $archivepath = pathutils\Replace-FileExtension $outfile "-$(get-date -Format "yyyy-MM-dd")$suffix.csv"
    copy-item $outfile $archivepath

    if ($timesheetUrl -eq $null) {
        $timesheetUrl = read-host "Enter url to your online timesheet"
    }
    $c = @{
        timestamp = (get-date)
        board = $board
        timesheetUrl = $timesheetUrl
    }
    $c | export-cache -container "kanban-log"
    
    start $outfile
    if ((test-path "$psscriptroot\timesheet.xlsm")) { 
        #start "$psscriptroot\timesheet.xlsm"
        if ($c.timesheetUrl -ne $null) {
            start $c.timesheetUrl # use office online
        }
    }


} finally {
	popd
}




