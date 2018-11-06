Import-Module SCCMPackageAutomation -Force
$Output = Get-OutDatedApps -HTML | Out-String


$Date = Get-Date -DisplayHint Date | Out-String
$Date = $Date -replace "`n","" -replace "`r",""
$DateTime = Get-Date
$Subject = "Out Of Date Apps For $Date"
$Recipients = "" #array of email address
# Email Body
$Body = @"
<body>
<head>
<style>
div {
    padding: 10px;
    background-color: #222222;
}
</style>
</head>
<html>
<p>Ran on $DateTime</p>
<div>
$Output
</div>
</html></body>
"@

Send-MailMessage -To $Recipients -From