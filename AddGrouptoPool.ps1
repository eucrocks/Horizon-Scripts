#Uncomment and run first line to create encrypted password in password.txt then remove or comment out.
#read-host -assecurestring | convertfrom-securestring | out-file password.txt

#Specify domain user in line below with Horizon admin privileges with password from previous step
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "<domain>\<user>",(get-content .\password.txt | ConvertTo-SecureString)

#Specify Connection server to connect to below
connect-hvserver -server cs01 -cred $cred

#Entitle Group to desktop pool
New-HVEntitlement -ResourceName <pool> -Type Group -User <domain>\<group>
