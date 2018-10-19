$Functions = Get-Command -Module HM-Functions
Foreach ($function in $functions) {
    Get-Help $Function.Name
}