$owner = $env:subrepo_owner
$repoName=$env:subrepo_name
$repo = "$owner/$repoName"

$branch = $env:subrepo_branch
if ($branch -eq $null) {
	$branch = "dev"
    write-host "will use default branch '$branch'"
} else {
    write-host "will use configured branch '$branch'"
}

write-host "testing if ssh is available"
get-command "ssh.exe" -ErrorAction Stop


#use ssh from git
'[ui]' | out-file  "$env:USERPROFILE/mercurial.ini" -Append -Encoding utf8
'ssh=ssh.exe' | out-file "$env:USERPROFILE/mercurial.ini" -Append -Encoding utf8

$bbhostkey = @"
bitbucket.org,104.192.143.3 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
"@


write-host "adding bitbucket to known_hosts"
$bbhostkey | out-file "$env:USERPROFILE/.ssh/known_hosts" -Append -Encoding utf8

write-host "adding private key"
$fileContent = "-----BEGIN RSA PRIVATE KEY-----`n"
$fileContent += $env:priv_key.Replace(' ', "`n")
$fileContent += "`n-----END RSA PRIVATE KEY-----`n"
Set-Content "$env:USERPROFILE\.ssh\id_rsa" $fileContent

write-host "testing ssh"
ssh hg@bitbucket.org "hg -R $repo"

write-host "cloning ssh://hg@bitbucket.org/$repo to $reponame"
hg clone --verbose ssh://hg@bitbucket.org/$repo $repoName

pushd

cd $repoName

write-host "updating to $branch"
hg update $branch 

hg summary


	$message = hg log -r . -T "{desc}"
	$id = hg log -r . -T "{node}"
	$ts = hg log -r . -T "{date|isodate}"
	$ts = [DateTime]::Parse($ts)
	$authorname = hg log -r . -T "{author|person}"
	$authormail = hg log -r . -T "{author|email}"
	$br = hg log -r . -T "{branch}"
	
	write-host "id:$id branch:$br msg:$message date:$ts author:$authorname mail:$authormail"
	
if ($env:appveyor -ne $null) {
	Update-AppveyorBuild -message "$message : [$br](https://bitbucket.org/$repo/commits/$id)" -Committed $ts -CommitterName $authorname -CommitterEmail $authorEmail 
	#-CommitId $id

	#Update-AppveyorBuild [-Version <string>] [-Message <string>]
	#       [-CommitId <string>] [-Committed <DateTime>]
	#       [-AuthorName <string>] [-AuthorEmail <string>]
	#       [-CommitterName <string>] [-CommitterEmail <string>]
}

popd

