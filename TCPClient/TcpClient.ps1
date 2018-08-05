param( [string]$server, [string]$port, [string]$data )
Try {
$buffer = new-object System.Byte[] 2048
$encoding = new-object System.Text.UTF8Encoding
$tcpConnection = New-Object System.Net.Sockets.TcpClient($server, $port)
if($tcpConnection.Connected){
	$tcpStream = $tcpConnection.GetStream()
	$data = $data +"`r`n`r`n"
	$bytes = $encoding.GetBytes($data)
	$tcpStream.Write($bytes,0, $bytes.Length)
	start-sleep -Milliseconds 1000
	if ($tcpStream.DataAvailable){
		$rawresponse = $tcpStream.Read($buffer, 0, 2048) 
		$response = $encoding.GetString($buffer, 0, $rawresponse)
		Write-Host "$response"
    }
$tcpStream.Dispose()
$tcpStream.Close()
}
} catch { Write-Host $_.Exception.Message
}finally{
    $tcpConnection.Close()
    stop-process -name powershell
    exit 0
}
