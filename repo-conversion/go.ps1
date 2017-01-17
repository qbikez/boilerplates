pushd 
try {
    cd $PSScriptRoot
    .\hg-convert C:\legimi\legimi.default C:\legimi\wm-audio -startrev 45847 -desttype git -force
} finally {
popd
}