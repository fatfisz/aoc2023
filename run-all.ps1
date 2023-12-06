$cwd = Get-Location

foreach ($dir in Get-ChildItem -Directory) {
    Write-Host "Running tests in ${dir}:"
    cd $dir

    foreach ($test in Get-ChildItem *.in) {
        $_ = $test -match '\\([^\\]+)\.in$'
        $test = $Matches[1]
        Write-Host "  Test $test"
        zig build run -- $test

        if (!$?) {
            break
        }
    }

    if (!$?) {
        break
    }
}

cd $cwd
