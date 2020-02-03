#This is the simple of password encryption script: input GD login and password.
#varibles
$passpath="c:\temp\power\passfile.txt"
$keypath="c:\temp\power\password_aes.key"

# Get Credentials
$Cred = Get-Credential

# Create 256 bit AES key
$AESKey = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
$AESKey | out-file $keypath
$Cred.Password| ConvertFrom-SecureString -Key (get-content C:\temp\password_aes.key)| Set-Content $passpath
