#dedicado a mi Katrina (Sofia Alejandra), ojala algun dia estudies "Ingenieria Nacional"
#el siguiente script permite calcular:
#ARQC: ISO8583 Emv Tag 9F26 Application Cryptogram (AC), MAC (Message Authentication Code ISO9797)
#CVV (Card Verification Value), UDK(Unique Derived Key)
#Mediante metodos de cifrado como DES y Triple DES 
param([string]$llaveMDK,[string]$llavePIN,[string]$llaveCVK,										
	  [string]$PAN,[string]$expDate,[string]$ATC,[string]$UN,										
	  [string]$serviceCode,[string]$PIN,[string]$terminalData)										
begin{																								
$llaveMDK = "DE02000000000000DE02000000000303"														
$llavePIN = "1C8ADCD54A16E680EAE02F45230BBAE0"															
$llaveCVK = "4F51EA5D8F911CEF70DC5D9813E9D50B"														
$PAN = "6016607052122554"																			
$expDate = "2412"
$ATC = "0001"
$UN = "30901B6A"  
$serviceCode = "999"
$PIN = "1234"               
$terminalData = "000002500000000000000000017002000480000170171004009C28F7755800058DA00003220000"
                
																										
function bitshift { 																				
param([int]$x,[int]$shift) 																				
return [math]::Floor($x * [math]::Pow(2,$shift))													
}																																														
function XOR{																						
param([Byte[]]$byte1,[Byte[]]$byte2)																
$array = @()																							
for ($i = 0; $i -lt $byte1.Length ; $i += 1)																
{																									
	$array += $byte1[$i] -bxor $byte2[$i]															
}																									
return $array    																								
}																									
																									
function ByteToHex {																					
param([Byte[]]$Bin)																						
$array = -join ($Bin |  foreach { "{0:X2}" -f $_ })																	
return $array																							
}																											
																									
function HexToByte {																									
param([string]$string)																									
$array = @()																										
$tipoHex = [System.Globalization.NumberStyles]::HexNumber																			
for ($i = 0; $i -lt $string.Length ; $i += 2)																			
{																									
	$array+= [Byte]::Parse($string.Substring($i, 2), $tipoHex)													
}																												
return $array																								
}																									
																							
function TDES_CBC { 																				
param([Byte[]]$dataBytes,[Byte[]]$keyBytes)																	
$tdes = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider						
$encoding = new-object System.Text.UTF8Encoding   													
$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC												
$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros											
$tdes.Key = $keyBytes																						
$tdes.IV = @(0,0,0,0,0,0,0,0)																					
$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   																
$mStream = New-Object System.IO.MemoryStream																		
$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write																			
$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 														
$cStream.Write($dataBytes, 0, $dataBytes.Length)															
$cStream.FlushFinalBlock()																						
$cStream.Close()
$cifra = $mStream.ToArray()
#Write-Host "TDES_CBC"
#Write-Host "Clave: $keyBytes"
#Write-Host "Datos: $dataBytes"
#Write-Host "cifra: $cifra"

																						
return $mStream.ToArray()																								
}																										
																											
function TDES_ECB { 																													
param([Byte[]]$dataBytes,[Byte[]]$keyBytes)																							
$tdes = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider													
$encoding = new-object System.Text.UTF8Encoding   																	
$tdes.Mode = [System.Security.Cryptography.CipherMode]::ECB																
$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros																		
$tdes.Key = $keyBytes																											
$tdes.IV = @(0,0,0,0,0,0,0,0)																											
$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   																										
$mStream = New-Object System.IO.MemoryStream																										
$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write																									
$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 																				
$cStream.Write($dataBytes, 0, $dataBytes.Length)																											
$cStream.FlushFinalBlock()																									
$cStream.Close()																										
return $mStream.ToArray()																									
}																										
																										
function DES_CBC { 																									
param([Byte[]]$dataBytes,[Byte[]]$keyBytes)																						
$tdes = New-Object System.Security.Cryptography.DESCryptoServiceProvider																		
$encoding = new-object System.Text.UTF8Encoding   																															
$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC																											
$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros																										
$tdes.Key = $keyBytes																														
$tdes.IV = @(0,0,0,0,0,0,0,0)																												
$ict = $tdes.CreateEncryptor($tdes.Key, $tdes.IV)   																											
$mStream = New-Object System.IO.MemoryStream																												
$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write																											
$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 																									
$cStream.Write($dataBytes, 0, $dataBytes.Length)																																
$cStream.FlushFinalBlock()																														
$cStream.Close()																														
return $mStream.ToArray()																															
}																										
																																	
function DES_CBCdecryptor { 																															
param([Byte[]]$dataBytes,[Byte[]]$keyBytes)																																
$tdes = New-Object System.Security.Cryptography.DESCryptoServiceProvider																														
$encoding = new-object System.Text.UTF8Encoding   																															
$tdes.Mode = [System.Security.Cryptography.CipherMode]::CBC																															
$tdes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros																														
$tdes.Key = $keyBytes																															
$tdes.IV = @(0,0,0,0,0,0,0,0)																													
$ict = $tdes.CreateDecryptor($tdes.Key, $tdes.IV)   																									
$mStream = New-Object System.IO.MemoryStream																											
$modoWrite = [System.Security.Cryptography.CryptoStreamMode]::Write																										
$cStream = New-Object System.Security.Cryptography.CryptoStream($mStream, $ict, $modoWrite) 																											
$cStream.Write($dataBytes, 0, $dataBytes.Length)																														
$cStream.FlushFinalBlock()																														
$cStream.Close()																													
return $mStream.ToArray()																																
}																															
																																	
function CheckOddParity																																
{																																		
param([Byte[]]$keyBytes)																														
for ($i = 0; $i -lt $keyBytes.Length ; $i += 1)																										
{																															
	$keyByte = $keyBytes[$i] -band 0xFE																													
	$parity = 0																									
	for($b=$keyByte;$b -ne 0;$b = bitshift $b -1){																										
		$bit = $b -band 1																														
		$parity = $parity + $bit																															
	}																																
	if($parity % 2 -eq 0){																																		
		$keyBytes[$i] = $keyByte -bor 1																										
	}																																	
	else{																																
		$keyBytes[$i] = $keyByte -bor 0																																	
	}  																																					
	}																																				
return $keyBytes																																	
}																																		
																																
function UDK																																			
{   																																			
param([string]$PAN,[string]$MDK)																															
$one = HexToByte "FFFFFFFFFFFFFFFF"																																
$key  = HexToByte $MDK																																
$Y = HexToByte ($PAN+"00").Substring(2)#todas las letras desde la posicion 2																											
$Y2 = XOR $Y $one																													
$ZL = ByteToHex (TDES_CBC $Y $key)																														
$ZR = ByteToHex (TDES_CBC $Y2 $key)																															
$UDK = HexToByte "$ZL$ZR"																														
$UDK = CheckOddParity $UDK																																
$UDK = ByteToHex $UDK																																		
return "$UDK" 																																		
}																																				
																																
function SessionKey																																			
{																																	
param([string]$ATC,[string]$UN,[string]$UDKin)																														
$UDK = HexToByte $UDKin																												
$RL  = HexToByte ($ATC+"F000"+$UN)																															
$RR  = HexToByte ($ATC+"0F00"+$UN)																															
$SL = ByteToHex (TDES_CBC $RL $UDK)																															
$SR = ByteToHex (TDES_CBC $RR $UDK)																																
return "$SL$SR"																																		
}																																
																																	
function MAC																																	
{																																			
#EMV_Book_2 A1.2 Message Authentication Code(ISO9797)																														
#Hi := ALG(KSL)[Xi xor Hi-1], for i = 1, 2, . . . , k																																	
param([string]$plainTextin,[string] $desKey)																																
#divide el texto de entrada en bloques de 16 letras																														
$plainTexts = [regex]::split($plainTextin, '(.{16})') | ? {$_}																														
$SL = HexToByte $desKey																																
$cipherText = HexToByte $plainTexts[0]																																		
for ($i = 0; $i -clt $plainTexts.Count; $i++)																																	
{																																	
	if ($i -cgt 0)																																
	{																																						
		$Xi = HexToByte $plainTexts[$i]																																
		$cipherText = XOR $Xi $cipherText																													
	}																																		
	$cipherText = DES_CBC $cipherText $SL																											
}																																					
$cipherText = ByteToHex $cipherText    																																			
return "$cipherText"																																						
}																																								
																																										
function ARQC																														
{																																		
param([string]$plainTextin, [string] $desKey)																												
$plainText = $plainTextin + "80" #relleno 80, para que tenga 32 letras																													
$SL = $desKey.Substring(0,16)																														
$mac = MAC $plainText $SL																																
$mac = HexToByte $mac																																
$SL = HexToByte $desKey.Substring(0,16)																																		
$SR = HexToByte $desKey.Substring(16,16)																																		
$arqc = DES_CBCdecryptor $mac $SR																															
$arqc = DES_CBC $arqc $SL																															
$arqc = ByteToHex $arqc																																	
return "$arqc"																																		
}																																									
																																
function PIN																																		
{																																	
param([string]$PANin, [string] $PINin, [string]$llavePIN)																													
$llave = $llavePIN																															
$llave = HexToByte $llave																																	
$PAN = "0000" + $PANin.Substring(3,12)																														
$PAN = HexToByte $PAN																																
$PIN = "04"+$PINin+"FFFFFFFFFF"																																	
$PIN = HexToByte $PIN																																
$pinBlock = XOR $PAN $PIN																																
$pin = TDES_ECB $pinBlock $llave   																																		
$pin = ByteToHex $pin    																																
return "$pin"																																
}																																				
																																		
function CVV																																		
{																																					
param([string]$PANin, [string] $Datein, [string] $ServiCode,[string]$llaveCVK)																										
$udk = HexToByte $llaveCVK																																		
$udka = $llaveCVK.Substring(0,16)																															
$udka = HexToByte $udka  																																		
$bloque = $PANin+$Datein+$ServiCode+"000000000"																																					
$bloqueA = $bloque.SubString(0,16)																																		
$bloqueB = $bloque.SubString(16,16)																																			
$bloqueA = HexToByte $bloqueA																													
$bloqueB = HexToByte $bloqueB																														
$bc = DES_CBC $bloqueA $udka																														
$bd = XOR $bc $bloqueB 																																						
$be = TDES_ECB $bd $udk 																																			
$Bloquecvv = ByteToHex $be																																		
$cvv = ""																																		
for($i=0; $i -lt $Bloquecvv.length ;$i+=1 )																																					
{																																				
	if($Bloquecvv[$i] -lt 'A'){																																					
		$cvv += $Bloquecvv[$i]																																			
	}																															
}																															
$cvv = $cvv.Substring(0,3)    																															
return "$cvv"																																		
}																																		
																																				
#comienzo del proceso 																															
$udk = UDK $PAN $llaveMDK																															
Write-Host "UDK:$udk"																																
																																			
$sessionKey = SessionKey $ATC $UN $udk																														
Write-Host "SessionKey:$sessionKey"																																				
																																			
$arqc = ARQC  $terminalData $sessionKey																																			
Write-Host "ARQC:$arqc"																															
																																	
$pin = PIN $PAN $PIN $llavePIN																																										
Write-Host "PIN:$pin"																																			
																																				
$cvv = CVV $PAN $expDate $serviceCode $llaveCVK																																				
Write-Host "CVV:$cvv"																																					
																																						
#Get-Process powershell | Stop-Process																																
																																			
}#END BIGIN																																					
																																									