
function install-rubydk() {
    pushd
    try {
        # RUBY
        if ($null -eq (get-command "ruby" -erroraction ignore)) {
            write-host "installing Ruby..."
            invoke-asadmin { choco install -y ruby }
            refresh-env
        }
        # Bundler
        if ($null -eq (get-command bundle -erroraction ignore)) {
            write-host "installing bundler..."
            gem install bundler
        }

        
        if (!(test-path .install)) { mkdir .install }

        # RUBY DK
        $rubydevkit = "c:\tools\ruby-devkit"
        if (!(test-path $rubydevkit)) {
            write-host "installing ruby-devkit..."
            $inst = ".install\DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe"
            if (!(test-path $inst)) {
                wget http://dl.bintray.com/oneclick/rubyinstaller/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe -outfile $inst 
            }
            cmd /c "$inst" -o"$rubydevkit" -y
        }
        cd $rubydevkit
        ruby dk.rb init
        # append:
        # - c:/tools/ruby23
        # to config.yml
        $ruby = where-is ruby # C:\tools\ruby23\bin\ruby.exe
        if ($ruby -eq $null) { throw "Ruby not found on path!" }
        $rubyDir = split-path -Parent (split-path -parent $ruby.source)
        $rubyDir = $rubyDir.Replace("\","/")
        write-host "ruby dir='$rubyDir'"
        "- $rubyDir" | out-file "config.yml" -Append utf8
        ruby dk.rb install
    } finally {
        popd
    }
}