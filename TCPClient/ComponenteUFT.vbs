Option explicit
On error resume next


Dim script,server,port,mensaje,respuesta

script = "C:/Users/automatizacion/POS/TcpClient.ps1"
CrearScript script

server = "216.58.222.196" ' IP de google
port = "80"
mensaje = "GET / HTTP/1.1" 

respuesta = ExecutePowershellScript(script,server,port,mensaje)
print respuesta

'DeleteFileIfExists script

Sub CrearScript(script)

	Dim s, filesys, objFile
	Set filesys = CreateObject("Scripting.FileSystemObject")
	If filesys.FileExists(script) Then 
		filesys.DeleteFile script 
	End If
	
	s = "param( [string]$server, [string]$port, [string]$data )"
	s = s & vbCrLf
	s = s & "Try {"
	s = s & vbCrLf
	s = s & "$buffer = new-object System.Byte[] 2048"
	s = s & vbCrLf
	s = s & "$encoding = new-object System.Text.UTF8Encoding"
	s = s & vbCrLf
	s = s & "$tcpConnection = New-Object System.Net.Sockets.TcpClient($server, $port)"
	s = s & vbCrLf
	s = s & "if($tcpConnection.Connected){"
	s = s & vbCrLf
	s = s & "	$tcpStream = $tcpConnection.GetStream()"
	s = s & vbCrLf
	s = s & "	$data = $data +"+chr(34) & "`r`n`r`n" & chr(34)
	s = s & vbCrLf
	s = s & "	$bytes = $encoding.GetBytes($data)"
	s = s & vbCrLf
	s = s & "	$tcpStream.Write($bytes,0, $bytes.Length)"
	s = s & vbCrLf
	s = s & "	start-sleep -Milliseconds 1000"
	s = s & vbCrLf
	s = s & "	if ($tcpStream.DataAvailable){"
	s = s & vbCrLf
	s = s & "		$rawresponse = $tcpStream.Read($buffer, 0, 2048) "
	s = s & vbCrLf
	s = s & "		$response = $encoding.GetString($buffer, 0, $rawresponse)"
	s = s & vbCrLf
	s = s & "		Write-Host " & chr(34) & "$response" & chr(34)
	s = s & vbCrLf
	s = s & "    }"
	s = s & vbCrLf
	s = s & "$tcpStream.Dispose()"
	s = s & vbCrLf
	s = s & "$tcpStream.Close()"
	s = s & vbCrLf
	s = s & "}"
	s = s & vbCrLf
	s = s & "} catch { Write-Host $_.Exception.Message"
	s = s & vbCrLf
	s = s & "}finally{"
	s = s & vbCrLf
	s = s & "    $tcpConnection.Close()"
	s = s & vbCrLf
	s = s & "    stop-process -name powershell"
	s = s & vbCrLf
	s = s & "    exit 0"
	s = s & vbCrLf
	s = s & "}"
	
	Set objFile = filesys.CreateTextFile(script,True)
	objFile.Write s & vbCrLf
	objFile.Close
	
End Sub

Function ExecutePowershellScript(script,server ,port, data)

	Dim oShell, oExec, command
	
	command = "powershell.exe  opciones -file script <<server>> <<port>> <<data>>"
	command = Replace(command,"<<",chr(34))
	command = Replace(command,">>",chr(34))
	command = Replace(command,"opciones","-WindowStyle Hidden -NonInteractive -executionpolicy bypass")
	command = Replace(command,"script",script)
	command = Replace(command,"server",server)
	command = Replace(command,"port",port)
	command = Replace(command,"data",data)

	Set oShell = CreateObject("WSCript.shell")
	Set oExec = oShell.Exec(command)
	ExecutePowershellScript = oExec.StdOut.ReadAll
	
End Function

Sub DeleteFileIfExists(script)
	Dim filesys 
	Set filesys = CreateObject("Scripting.FileSystemObject") 
	If filesys.FileExists(script) Then 
		filesys.DeleteFile script 
	End If
End Sub