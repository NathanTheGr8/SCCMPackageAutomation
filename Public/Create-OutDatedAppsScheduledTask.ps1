function Create-OutDatedAppsScheduledTask {
    <#
    .SYNOPSIS

    Creates a scheudled task to check Get-OutdatedApps and email people.
    .DESCRIPTION

    .EXAMPLE
    #>
    [CmdletBinding()]
    param
    (
    )

    $ScriptPath = "$PSScriptRoot\Private\GetOutOfDateAppsScheduleTask.ps1"
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Arguguement "-NoProfile -WindowStyle Hidden -command '$ScriptPath'"
    $trigger =  New-ScheduledTaskTrigger -Daily -At 8am
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GetOutdatedApps" -Description "Powershell script that records outdated apps daily"

}
