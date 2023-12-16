$cwd = Get-Location

try {
    foreach ($dir in Get-ChildItem -Directory) {
        Write-Host "Running tests in ${dir}:"
        Set-Location $dir

        foreach ($test in Get-ChildItem *.in) {
            $test -match '\\([^\\]+)\.in$' > $null
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
}
finally {
    Set-Location $cwd
}
