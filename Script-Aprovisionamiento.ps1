
# 1. Variables base del tenant y credenciales
$UPNSuffix = "malastro.onmicrosoft.com"
$Password = Read-Host "Introduce la contraseña temporal para los usuarios" -AsSecureString

# 2. Crear usuarios en la OU correspondiente
New-ADUser -Name "Antonio Recio" -GivenName "Antonio" -Surname "Recio" `
    -SamAccountName "arecio" -UserPrincipalName "arecio@$UPNSuffix" `
    -Path "OU=Usuarios,OU=Montepinar,DC=montepinar,DC=local" `
    -AccountPassword $Password -Enabled $true -PasswordNeverExpires $true

New-ADUser -Name "Enrique Pastor" -GivenName "Enrique" -Surname "Pastor" `
    -SamAccountName "epastor" -UserPrincipalName "epastor@$UPNSuffix" `
    -Path "OU=Usuarios,OU=Montepinar,DC=montepinar,DC=local" `
    -AccountPassword $Password -Enabled $true -PasswordNeverExpires $true

# 3. Añadir miembros al grupo de seguridad
Add-ADGroupMember -Identity "Directiva-Montepinar" -Members "arecio", "epastor"

