$LogName = "OpenSSH/Operational"
$ShowExisting = 10
$hostAddr = "tcp://$((Get-NetIPConfiguration).IPv4DefaultGateway.NextHop.ToString()):2375"

setx.exe DOCKER_HOST "$hostAddr" /M
sc.exe start sshd 

if ($ShowExisting -gt 0) {
    $Data = Get-WinEvent -LogName $LogName -MaxEvents $ShowExisting -ErrorAction Continue
    $Data |Sort-Object -Property RecordId
    $Index1 = $Data[0].RecordId
}
else {
    $Index1 = (Get-WinEvent -LogName $LogName -MaxEvents 1 -ErrorAction Continue).RecordId
}

while ($true) {
    Start-Sleep -Seconds 1
    $Index2  = (Get-WinEvent -LogName $LogName -MaxEvents 1 -ErrorAction Continue).RecordId 
    if ($Index2 -gt $Index1) {
        Get-WinEvent -LogName $LogName -MaxEvents ($Index2 - $Index1) -ErrorAction Continue | Sort-Object -Property RecordId | Select-Object -ExpandProperty message
    }
    $Index1 = $Index2
}

