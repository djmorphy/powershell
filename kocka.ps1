Write-Host 'Hello World!'

$a = 5
$a

New-Variable -Name b -Value 6
$b 

$alma = 'korte'

Set-Variable -Name $alma -Value 'barack'
$alma 
$korte

Write-Host 'alma $a'
Write-Host "alma $a"

 ${c:\Users\DjMor\OneDrive\dev\powershell\Kockaképző\a.txt} = 'AAA'
 ${c:\Users\DjMor\OneDrive\dev\powershell\Kockaképző\a.txt} += 'BBB'
 ${c:\Users\DjMor\OneDrive\dev\powershell\Kockaképző\a.txt} += 'CCCC'
 
 Get-Content .\a.txt
 
 Get-Alias
 
 cat .\a.txt
 
 dir -Recurse
 
 notepad s1.ps1