Option Explicit
On error resume next

Dim DDTParam: Set DDTParam = CreateObject("Scripting.Dictionary")

DDTParam.Add "sRutaTrabajo","C:/Users/automatizacion/POS/"

DDTParam.add "LlaveARQC", "DE02000000000000DE02000000000303"
DDTParam.add "LlavePIN", "1C8ADCD54A16E680EAE02F45230BBAE0"
DDTParam.add "LlaveCVK", "4F51EA5D8F911CEF70DC5D9813E9D50B"

DDTParam.add "_9F02","000002500000"
DDTParam.add "_9F03","000000000000"
DDTParam.add "_9F1A","0170"
DDTParam.add "_95", "0200048000"
DDTParam.add "_5F2A","0170"
DDTParam.add "_9A","171004"
DDTParam.add "_9C","00"
DDTParam.add "_9F37","9C28F775" 'UN Unpredecible number
DDTParam.add "_82","5800"
DDTParam.add "_9F36","058D"  'ATC
DDTParam.add "_9F10", "A00003220000"



'DDTParam.Add "ServiceCode","220"
DDTParam.Add "ServiceCode","999"

Dim DDT: Set DDT = CreateObject("Scripting.Dictionary")

DDT.add "NumTarjeta", "6016607052122539"
DDT.add "ClaveTarjeta", "1234"
DDT.add "FecExpiracionTar", "2012"

Dim terminalData
terminalData = DDTParam("_9F02") & DDTParam("_9F03") & DDTParam("_9F1A") & _
               DDTParam("_95") & DDTParam("_5F2A") & DDTParam("_9A") & _
               DDTParam("_9C") & DDTParam("_9F37") & DDTParam("_82") & _
               DDTParam("_9F36") & DDTParam("_9F10")

print "Terminal data: " & terminalData


ExecutePowershellScript

Sub ExecutePowershellScript
	
Dim oShell, oExec, command, script
Dim resultado
Dim sArchivoSalida : sArchivoSalida = DDTParam("sRutaTrabajo") & "temp.txt"
	'script = DDTParam("sRutaTrabajo") & "MyTcpClient.ps1"
	
 	script = "C:/Users/automatizacion/POS/criptography.ps1"
 	CrearSCript script
 	
 	'command = "cmd /c powershell.exe -executionpolicy bypass -file c:\print.ps1 > c:/temp.txt"
 	'command = "cmd /K CD C:\ & Dir > c:/temp.txt"
 	
	command = "cmd /c powershell.exe  opciones -file script <<llaveMDK>> <<llavePIN>> <<llaveCVK>> <<PAN>> <<expDate>> <<ATC>> <<UN>> <<serviceCode>> <<PIN>> <<terminalData>> > c:/temp.txt "
	command = Replace(command,"opciones","-WindowStyle Hidden -NonInteractive  -executionpolicy bypass")
	command = Replace(command,"<<",chr(34))
	command = Replace(command,">>",chr(34))
	command = Replace(command,"script",script)
	command = Replace(command,"llaveMDK", DDTParam("LlaveARQC") )
	command = Replace(command,"llavePIN", DDTParam("LlavePIN") )
	command = Replace(command,"llaveCVK", DDTParam("LlaveCVK"))
	command = Replace(command,"PAN", DDT("NumTarjeta") )
	command = Replace(command,"expDate",DDT("FecExpiracionTar") )
	command = Replace(command,"ATC", DDTParam("_9F36") )
	command = Replace(command,"UN", DDTParam("_9F37") )
	command = Replace(command,"serviceCode", DDTParam("ServiceCode") )
	command = Replace(command,"PIN",DDT("ClaveTarjeta"))
	command = Replace(command,"terminalData",terminalData)
	
	'print command
	
	Set oShell = CreateObject("WSCript.shell")
	
	 oShell.Run command ,0,true
	'wait 2
	
	Dim fso,file
	Set fso  = CreateObject("Scripting.FileSystemObject")
	Set file = fso.OpenTextFile("c:/temp.txt", 1)
	resultado = file.ReadAll
	file.Close
	DeleteFileIfExists sArchivoSalida
	
	'resultado = oExec.StdOut.ReadAll
	
	Dim sarqc : sarqc = split(resultado,"ARQC:")
	Dim arqc  :  arqc = mid(sarqc(1),1,16)
	
	Dim spin  : spin  = split(resultado,"PIN:")
	Dim pin   :  pin  = mid(spin(1),1,16)
	
	Dim scvv  : scvv  = split(resultado,"CVV:")
	Dim  cvv  : cvv   = mid(scvv(1),1,3)
	
	DDT.Add "ARQC", arqc
	
	print "ARQC: " & arqc
	print "PIN: " & pin
	print "CVV: " & cvv
	
	Dim token: token = DDTParam("_95") & DDT("ARQC") & DDTParam("_9F02") & DDTParam("_9F03") & DDTParam("_82") & _
                DDTParam("_9F36") & mid(cstr(DDTParam("_9F1A")),2) & mid(cstr(DDTParam("_5F2A")),2) & DDTParam("_9A") & _
                DDTParam("_9C") & DDTParam("_9F37") & "00180110" & DDTParam("_9F10")
                
   	print "token: " & token

	'DeleteFileIfExists script
End Sub

Sub CrearSCript(script)
	
	Dim s, filesys, objFile
	Set filesys = CreateObject("Scripting.FileSystemObject")
	If filesys.FileExists(script) Then 
		filesys.DeleteFile script 
	End If
	
	Set objFile = filesys.CreateTextFile(script,True)

'El siguiente fragmento representa el punto de entrada a la funcion, en ella se pueden observar los nombres de los parametros
'Estan comentariados(#) y encerrados en comillas simples (') los valores de ejmplo que podrian tomar las variables  
s = "" _
&"param([string]$llaveMDK,[string]$llavePIN,[string]$llaveCVK,										" & vbCrLf _
&"	  [string]$PAN,[string]$expDate,[string]$ATC,[string]$UN,										" & vbCrLf _
&"	  [string]$serviceCode,[string]$PIN,[string]$terminalData)										" & vbCrLf _
&"begin{																							" & vbCrLf 
objFile.Write s

'La siguiente funcion implementa el Desplazamiento de bits ( >> desplazamiento a la derecha) o (<< desplazamiento a la izquierda) 
'Este operador se encuentra en la mayoria de los lenguajes de programacion (Java, C#, ...)
'Inclusive en la V3 de Powershell, pero NO en la V2, por lo cual se implemento, en caso de que se ejectue el robot
'en una maquina que la version V2 de powershell.
'Esta funcion es utilizada en la funcion "CheckOddParity" para determinar si la Clave UDK tiene paridad impar (ver "CheckOddParity")
'La funcion recibe dos numeros enteros: el numero a desplazar (x) y el valor del desplazamiento (shift).
'Si se desea >> (shift) debe ser negativo. Ejemplo
' bitshift (43,-2 )   -> resultado 10
' 43 -> 101011        -> 001010
' Ver https://es.wikipedia.org/wiki/Operador_a_nivel_de_bits
s = "" _
&"function bitshift { 																				" & vbCrLf _
&"param([int]$x,[int]$shift) 																		" & vbCrLf _		
&"return [math]::Floor($x * [math]::Pow(2,$shift))													" & vbCrLf _
&"}		 																							" & vbCrLf	
objFile.Write s

'La siguiente funcion implementa el operador XOR sobre dos vectores (o arreglos) de bytes. Los dos vectores deben tener el mismo tamaño
'Ejemplo:
'$Vec1             200  35  ... 169  186 
'$Vec2              48 125  ... 160    4
'XOR($Vec1,$Vec2)  248  94  ...   9  190
s = "" _
&"function XOR{																						" & vbCrLf _
&"param([Byte[]]$byte1,[Byte[]]$byte2)																" & vbCrLf _
&"$array = @()																						" & vbCrLf _	
&"for ($i = 0; $i -lt $byte1.Length ; $i += 1)														" & vbCrLf _		
&"{																									" & vbCrLf _
&"	$array += $byte1[$i] -bxor $byte2[$i]															" & vbCrLf _
&"}																									" & vbCrLf _
&"return $array    																					" & vbCrLf _			
&"}																									" & vbCrLf
objFile.Write s

'La siguiente funcion Convierte un Vector de bytes a una Representacion Hexadecimal
'El caracter chr(34) representa las comillas dobles " que son necesarias en el codigo Powershell y como se esta embebiendo en UFT
'Es necesario concatenarlo como valor. Ejemplo
'          $Vec    = 200  35  ... 169  186 
'ByteToHex($Vec) ->   C823...A9BA 
s = "" _
&"function ByteToHex {																				" & vbCrLf _	
&"param([Byte[]]$Bin)																				" & vbCrLf _		
&"$array = -join ($Bin |  foreach { "&chr(34)& "{0:X2}"&chr(34)& " -f $_ })							" & vbCrLf _					
&"return $array																						" & vbCrLf _	
&"}																									" & vbCrLf 		
objFile.Write s

'La siguiente funcion realiza el proceso inverso de la anterior: Recibe una cada en Hexadecimal y la convierte a un Vector de Bytes
'Cabe resaltar que todas las fuciones criptograficas (TDES_CBC,DES_CBC,etc) y de nivel bytes como XOR, 
'necesitan que los datos se pasen en vectores de Bytes. Y los datos de entrada como por ejemplo las Claves o el numero de la tarjeta
'son tratados como Cadenas de bytes. Ejemplo, el numero de una tarjeta
'          $PAN  =  '6016607052122554'
'HexToByte($PAN) -> 96 22 96 112 82 18 37 84
s = "" _
&"function HexToByte {																				" & vbCrLf _					
&"param([string]$string)																			" & vbCrLf _					
&"$array = @()																						" & vbCrLf _				
&"$tipoHex = [System.Globalization.NumberStyles]::HexNumber											" & vbCrLf _								
&"for ($i = 0; $i -lt $string.Length ; $i += 2)														" & vbCrLf _					
&"{																									" & vbCrLf _
&"	$array+= [Byte]::Parse($string.Substring($i, 2), $tipoHex)										" & vbCrLf _			
&"}																									" & vbCrLf _			
&"return $array																						" & vbCrLf _		
&"}																									" & vbCrLf
objFile.Write s

'La siguiente funcion implementa el metodo de cifrado Triple DES en modo CBC
'El primer parametro son los datos a Cifrar (en vector de bytes) y el segundo la clave (Tambien en vector de Bytes)
'Ejemplo:
'                    $Datos: 5 141 15 0 156 40 247 117
'                    $Clave: 118 16 81 236 188 25 205 1 61 122 191 206 223 32 182 16
'TDES_CBC($Datos,$Clave)  -> 25 130 151 22 233 122 88 120
s = "" _
&"function TDES_CBC { 																				" & vbCrLf _
&"param([Byte[]]$dataBytes,[Byte[]]$keyBytes)														" & vbCrLf _				
&"$tdes = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider					" & vbCrLf _
&"$encoding = new-object System.Text.UTF8Encoding   												" & vbCrLf _
&"$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC										" & vbCrLf _		
&"$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros									" & vbCrLf _		
&"$tdes.Key = $keyBytes																				" & vbCrLf _		
&"$tdes.IV = @(0,0,0,0,0,0,0,0)																		" & vbCrLf _			
&"$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   												" & vbCrLf _				
&"$mStream = New-Object System.IO.MemoryStream														" & vbCrLf _				
&"$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write								" & vbCrLf _											
&"$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 		" & vbCrLf _												
&"$cStream.Write($dataBytes, 0, $dataBytes.Length)													" & vbCrLf _		
&"$cStream.FlushFinalBlock()																		" & vbCrLf _			
&"$cStream.Close()																					" & vbCrLf _	
&"return $mStream.ToArray()																			" & vbCrLf _					
&"}																									" & vbCrLf	
objFile.Write s

'La siguiente funcion implementa el metodo de Cififrado Triple DES en modo ECB. Similar a la anterior
s = "" _
&"function TDES_ECB { 																				" & vbCrLf _									
&"param([Byte[]]$dataBytes,[Byte[]]$keyBytes)														" & vbCrLf _									
&"$tdes = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider					" & vbCrLf _							
&"$encoding = new-object System.Text.UTF8Encoding   												" & vbCrLf _				
&"$tdes.Mode = [System.Security.Cryptography.CipherMode]::ECB										" & vbCrLf _						
&"$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros									" & vbCrLf _									
&"$tdes.Key = $keyBytes																				" & vbCrLf _							
&"$tdes.IV = @(0,0,0,0,0,0,0,0)																		" & vbCrLf _									
&"$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   												" & vbCrLf _														
&"$mStream = New-Object System.IO.MemoryStream														" & vbCrLf _												
&"$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write								" & vbCrLf _																	
&"$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 		" & vbCrLf _																		
&"$cStream.Write($dataBytes, 0, $dataBytes.Length)													" & vbCrLf _														
&"$cStream.FlushFinalBlock()																		" & vbCrLf _						
&"$cStream.Close()																					" & vbCrLf _					
&"return $mStream.ToArray()																			" & vbCrLf _						
&"}																									" & vbCrLf	
objFile.Write s

'La siguiente funcion implementa el metodo de Cififrado DES en modo CBC. Similar a la anterior
s = "" _
&"function DES_CBC { 																				" & vbCrLf _					
&"param([Byte[]]$dataBytes,[Byte[]]$keyBytes)														" & vbCrLf _								
&"$tdes = New-Object System.Security.Cryptography.DESCryptoServiceProvider							" & vbCrLf _											
&"$encoding = new-object System.Text.UTF8Encoding   												" & vbCrLf _																		
&"$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC										" & vbCrLf _																	
&"$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros									" & vbCrLf _																	
&"$tdes.Key = $keyBytes																				" & vbCrLf _										
&"$tdes.IV = @(0,0,0,0,0,0,0,0)																		" & vbCrLf _										
&"$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   												" & vbCrLf _															
&"$mStream = New-Object System.IO.MemoryStream														" & vbCrLf _														
&"$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write								" & vbCrLf _																			
&"$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 		" & vbCrLf _																							
&"$cStream.Write($dataBytes, 0, $dataBytes.Length)													" & vbCrLf _																			
&"$cStream.FlushFinalBlock()																		" & vbCrLf _											
&"$cStream.Close()																					" & vbCrLf _									
&"return $mStream.ToArray()																			" & vbCrLf _												
&"}																									" & vbCrLf 	
objFile.Write s

'La siguiente funcion implementa el metodo de DeCififrado DES en modo CBC. Similar a la anterior
s = "" _
&"function DES_CBCdecryptor { 																		" & vbCrLf _													
&"param([Byte[]]$dataBytes,[Byte[]]$keyBytes)														" & vbCrLf _																		
&"$tdes = New-Object System.Security.Cryptography.DESCryptoServiceProvider							" & vbCrLf _																							
&"$encoding = new-object System.Text.UTF8Encoding   												" & vbCrLf _																		
&"$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC										" & vbCrLf _																					
&"$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros									" & vbCrLf _																					
&"$tdes.Key = $keyBytes																				" & vbCrLf _											
&"$tdes.IV = @(0,0,0,0,0,0,0,0)																		" & vbCrLf _											
&"$ict = $tdes.CreateDecryptor($tdes.Key, $tdes.IV)   												" & vbCrLf _													
&"$mStream = New-Object System.IO.MemoryStream														" & vbCrLf _													
&"$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write								" & vbCrLf _																		
&"$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 		" & vbCrLf _																									
&"$cStream.Write($dataBytes, 0, $dataBytes.Length)													" & vbCrLf _																	
&"$cStream.FlushFinalBlock()																		" & vbCrLf _											
&"$cStream.Close()																					" & vbCrLf _								
&"return $mStream.ToArray()																			" & vbCrLf _
&"}																									" & vbCrLf
objFile.Write s

'La siguiente funcion hace una comprobacion de la paridad uno a uno de un conjuto de bytes.
'Esta funcion es utilizada en la generacion de la Clave UDK (funcion)
'Si un byte tiene paridad "par" se suma  1 (uno). (Sino 0 o lo que es lo mismo permanece igual).
'Cabe mencionar que la paridad no es lo mismo que si un numero es par o impar, sino si el numero de unos en un byte es par o impar. 
'La comprobacion se hace sobre los primeros 7 bits (el ultimo no cuenta y es remplazado por 0 (impar) o 1 (par) )
'ejemplo:
'$vec =        147            72            53    ...
'		 1001001 1     0100100 0     0011010 1    ...
'        (impar)3 1s   (par)2 1s    (impar)3 1s
'Resultado
'        1001001 0     0100100 1     0011010 0
'              146            73            52
s = "" _
&"function CheckOddParity																			" & vbCrLf _													
&"{																									" & vbCrLf _									
&"param([Byte[]]$keyBytes)																			" & vbCrLf _											
&"for ($i = 0; $i -lt $keyBytes.Length ; $i += 1)													" & vbCrLf _													
&"{																									" & vbCrLf _						
&"	$keyByte = $keyBytes[$i] -band 0xFE																" & vbCrLf _													
&"	$parity = 0																						" & vbCrLf _			
&"	for($b=$keyByte;$b -ne 0;$b = bitshift $b -1){													" & vbCrLf _													
&"		$bit = $b -band 1																			" & vbCrLf _											
&"		$parity = $parity + $bit																	" & vbCrLf _														
&"	}																								" & vbCrLf _								
&"	if($parity % 2 -eq 0){																			" & vbCrLf _															
&"		$keyBytes[$i] = $keyByte -bor 1																" & vbCrLf _										
&"	}																								" & vbCrLf _									
&"	else{																							" & vbCrLf _									
&"		$keyBytes[$i] = $keyByte -bor 0																" & vbCrLf _																	
&"	}  																								" & vbCrLf _													
&"	}																								" & vbCrLf _												
&"return $keyBytes																					" & vbCrLf _												
&"}																									" & vbCrLf									
objFile.Write s

'La siguiente funcion implementa la generacion de la clave de la tarjeta o UDK
'Ver EMV_Book_2 A1.4 Master Key Derivation Option A
s = "" _
&"function UDK																						" & vbCrLf _													
&"{   																								" & vbCrLf _											
&"param([string]$PAN,[string]$MDK)																	" & vbCrLf _														
&"$one = HexToByte "&chr(34)& "FFFFFFFFFFFFFFFF"&chr(34) &"											" & vbCrLf _																
&"$key  = HexToByte $MDK																			" & vbCrLf _												
&"$Y = HexToByte ($PAN+"&chr(34)& "00"&chr(34)& ").Substring(2)#todas las letras desde la posicion 2" & vbCrLf _																					
&"$Y2 = XOR $Y $one																					" & vbCrLf _								
&"$ZL = ByteToHex (TDES_CBC $Y $key)																" & vbCrLf _													
&"$ZR = ByteToHex (TDES_CBC $Y2 $key)																" & vbCrLf _															
&"$UDK = HexToByte "&chr(34)& "$ZL$ZR"&chr(34)& "													" & vbCrLf _											
&"$UDK = CheckOddParity $UDK																		" & vbCrLf _													
&"$UDK = ByteToHex $UDK																				" & vbCrLf _														
&"return "&chr(34)& "$UDK"&chr(34)& " 																" & vbCrLf _												
&"}																									" & vbCrLf											
objFile.Write s

'La siguiente funcion implementa la generacion de la clave de la session.
'Ver EMV_Book_2 A1.3 Session Key Derivation
s = "" _
&"function SessionKey																				" & vbCrLf _															
&"{																									" & vbCrLf _								
&"param([string]$ATC,[string]$UN,[string]$UDKin)													" & vbCrLf _																
&"$UDK = HexToByte $UDKin																			" & vbCrLf _									
&"$RL  = HexToByte ($ATC+"&chr(34)& "F000"&chr(34)& "+$UN)											" & vbCrLf _														
&"$RR  = HexToByte ($ATC+"&chr(34)& "0F00"&chr(34)& "+$UN)											" & vbCrLf _														
&"$SL = ByteToHex (TDES_CBC $RL $UDK)																" & vbCrLf _															
&"$SR = ByteToHex (TDES_CBC $RR $UDK)																" & vbCrLf _																
&"return "&chr(34)& "$SL$SR"&chr(34)& "																" & vbCrLf _													
&"}																									" & vbCrLf 							
objFile.Write s

'La siguiente funcion implementa el Calculo de la MAC
'Ver EMV_Book_2 A1.2 Message Authentication Code(ISO9797)
s = "" _
&"function MAC																						" & vbCrLf _											
&"{																									" & vbCrLf _																														
&"param([string]$plainTextin,[string] $desKey)														" & vbCrLf _																		
&"#divide el texto de entrada en bloques de 16 letras												" & vbCrLf _																		
&"$plainTexts = [regex]::split($plainTextin, '(.{16})') | ? {$_}									" & vbCrLf _																				
&"$SL = HexToByte $desKey																			" & vbCrLf _													
&"$cipherText = HexToByte $plainTexts[0]															" & vbCrLf _																		
&"for ($i = 0; $i -clt $plainTexts.Count; $i++)														" & vbCrLf _																			
&"{																									" & vbCrLf _								
&"	if ($i -cgt 0)																					" & vbCrLf _											
&"	{																								" & vbCrLf _														
&"		$Xi = HexToByte $plainTexts[$i]																" & vbCrLf _																
&"		$cipherText = XOR $Xi $cipherText															" & vbCrLf _														
&"	}																								" & vbCrLf _										
&"	$cipherText = DES_CBC $cipherText $SL															" & vbCrLf _												
&"}																									" & vbCrLf _												
&"$cipherText = ByteToHex $cipherText    															" & vbCrLf _																				
&"return "&chr(34)& "$cipherText"&chr(34)& "														" & vbCrLf _																		
&"}																									" & vbCrLf															
objFile.Write s

'La siguiente funcion implementa el Calculo de la ARQC
s = "" _
&"function ARQC																						" & vbCrLf _								
&"{																									" & vbCrLf _									
&"param([string]$plainTextin, [string] $desKey)														" & vbCrLf _														
&"$plainText = $plainTextin + "&chr(34)& "80"&chr(34)& " #relleno 80, para que tenga 32 letras		" & vbCrLf _																					
&"$SL = $desKey.Substring(0,16)																		" & vbCrLf _												
&"$mac = MAC $plainText $SL																			" & vbCrLf _													
&"$mac = HexToByte $mac																				" & vbCrLf _												
&"$SL = HexToByte $desKey.Substring(0,16)															" & vbCrLf _																			
&"$SR = HexToByte $desKey.Substring(16,16)															" & vbCrLf _																			
&"$arqc = DES_CBCdecryptor $mac $SR																	" & vbCrLf _														
&"$arqc = DES_CBC $arqc $SL																			" & vbCrLf _												
&"$arqc = ByteToHex $arqc																			" & vbCrLf _														
&"return "&chr(34)& "$arqc"&chr(34)& "																" & vbCrLf _												
&"}																									" & vbCrLf																
objFile.Write s

'La siguiente funcion implementa El calculo del PIN
' Ver https://eftlab.co.uk/index.php/site-map/knowledge-base/261-complete-list-of-pin-blocks-in-payments#ISO-0
s = "" _
&"function PIN																						" & vbCrLf _												
&"{																									" & vbCrLf _								
&"param([string]$PANin, [string] $PINin, [string]$llavePIN)											" & vbCrLf _																		
&"$llave = $llavePIN																				" & vbCrLf _										
&"$llave = HexToByte $llave																			" & vbCrLf _														
&"$PAN = "&chr(34)& "0000"&chr(34)& " + $PANin.Substring(3,12)										" & vbCrLf _														
&"$PAN = HexToByte $PAN																				" & vbCrLf _												
&"$PIN = "&chr(34)& "04"&chr(34)& "+$PINin+"&chr(34)& "FFFFFFFFFF"&chr(34)& "						" & vbCrLf _																
&"$PIN = HexToByte $PIN																				" & vbCrLf _												
&"$pinBlock = XOR $PAN $PIN																			" & vbCrLf _													
&"$pin = TDES_ECB $pinBlock $llave   																" & vbCrLf _																		
&"$pin = ByteToHex $pin    																			" & vbCrLf _													
&"return "&chr(34)& "$pin"&chr(34)& "																" & vbCrLf _										
&"}																									" & vbCrLf											
objFile.Write s

'La siguiente funcion implementa el calculo del CVV
'ver http://lordofcreditcards.blogspot.com.co/
s = "" _
&"function CVV																						" & vbCrLf _												
&"{																									" & vbCrLf _												
&"param([string]$PANin, [string] $Datein, [string] $ServiCode,[string]$llaveCVK)					" & vbCrLf _																				
&"$udk = HexToByte $llaveCVK																		" & vbCrLf _															
&"$udka = $llaveCVK.Substring(0,16)																	" & vbCrLf _														
&"$udka = HexToByte $udka  																			" & vbCrLf _															
&"$bloque = $PANin+$Datein+$ServiCode+"&chr(34)& "000000000"&chr(34)& "								" & vbCrLf _																								
&"$bloqueA = $bloque.SubString(0,16)																" & vbCrLf _																	
&"$bloqueB = $bloque.SubString(16,16)																" & vbCrLf _																			
&"$bloqueA = HexToByte $bloqueA																		" & vbCrLf _											
&"$bloqueB = HexToByte $bloqueB																		" & vbCrLf _												
&"$bc = DES_CBC $bloqueA $udka																		" & vbCrLf _												
&"$bd = XOR $bc $bloqueB 																			" & vbCrLf _																			
&"$be = TDES_ECB $bd $udk 																			" & vbCrLf _																
&"$Bloquecvv = ByteToHex $be																		" & vbCrLf _															
&"$cvv = "&chr(34)&chr(34)&"																		" & vbCrLf _											
&"for($i=0; $i -lt $Bloquecvv.length ;$i+=1 )														" & vbCrLf _																							
&"{																									" & vbCrLf _											
&"	if($Bloquecvv[$i] -lt 'A'){																		" & vbCrLf _																			
&"		$cvv += $Bloquecvv[$i]																		" & vbCrLf _																	
&"	}																								" & vbCrLf _							
&"}																									" & vbCrLf _						
&"$cvv = $cvv.Substring(0,3)    																	" & vbCrLf _													
&"return "&chr(34)& "$cvv"&chr(34)& "																" & vbCrLf _												
&"}																									" & vbCrLf 									
objFile.Write s

'El siguiente es el proceso paso a paso para para Calcular la ARQC, PIN y CVV
s = "" _
&"#comienzo del proceso 																			" & vbCrLf _											
&"$udk = UDK $PAN $llaveMDK																			" & vbCrLf _												
&"#Write-Host "&chr(34)& "UDK:$udk"&chr(34)& "														" & vbCrLf _												
&"																									" & vbCrLf _										
&"$sessionKey = SessionKey $ATC $UN $udk															" & vbCrLf _														
&"#Write-Host "&chr(34)& "SessionKey:$sessionKey"&chr(34)& "										" & vbCrLf _																				
&"																									" & vbCrLf _										
&"$arqc = ARQC  $terminalData $sessionKey															" & vbCrLf _																				
&"Write-Host "&chr(34)& "ARQC:$arqc"&chr(34)& "														" & vbCrLf _												
&"																									" & vbCrLf _								
&"$pin = PIN $PAN $PIN $llavePIN																	" & vbCrLf _																								
&"Write-Host "&chr(34)& "PIN:$pin"&chr(34)& "														" & vbCrLf _															
&"																									" & vbCrLf _											
&"$cvv = CVV $PAN $expDate $serviceCode $llaveCVK													" & vbCrLf _																							
&"Write-Host "&chr(34)& "CVV:$cvv"&chr(34)& "														" & vbCrLf _																	
&"																									" & vbCrLf _													
&"Get-Process powershell | Stop-Process																" & vbCrLf _																
&"																									" & vbCrLf _										
&"}#END BIGIN																						" 																								

objFile.Write s
objFile.Close
	
End Sub

Sub DeleteFileIfExists(script)
	Dim filesys 
	Set filesys = CreateObject("Scripting.FileSystemObject") 
	If filesys.FileExists(script) Then 
		filesys.DeleteFile script 
	End If
End Sub




