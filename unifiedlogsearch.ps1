### Microsoft 365 Audit Logs Downloader

# =============== CHANGE THESE =============== #
$upn = 'global.admin@tenant.onmicrosoft.com'
$days = 7 # days to check

$OutputFolder = "Microsoft_365_AuditLog"
# ============================================ #

# Microsoft 365 Login with MFA Enabled
$Session = Connect-ExchangeOnline -UserPrincipalName $upn -ShowProgress $true

$ErrorActionPreference = "Stop"

$currentDate = Get-Date
$Start = $currentDate.AddDays(-$days)
$EndDate = $currentDate

If(!(Test-Path $OutputFolder)) {
      New-Item -ItemType Directory -Force -Path $OutputFolder
}

"Window is from: $Start -> $EndDate"
do {
    # Download 3 hours at a time, until the start date/time is reached
    $StartDate = $EndDate.AddHours(-3)
    "Running search for $StartDate -> $EndDate"
    do {
        $time = Get-Date
        # Search the defined date(s), SessionId + SessionCommand in combination with the loop will return and append 5000 object per iteration until all objects are returned (maximum limit is 50k objects)
        do {
            try {
                $AuditOutput = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -SessionId "$StartDate -> $EndDate" -SessionCommand ReturnLargeSet -ResultSize 5000
                $errorvar = $false
            }
            catch {
                $errorvar = $true
                "An error occured. Trying again."
            }
        } while ($errorvar)
        if ($auditOutput) {
            "Results received (" + ($(Get-Date) - $time) + "), writing to file..."
            $filename = "$StartDate-$EndDate.csv".Replace(":",".").Replace("/","-")
            $auditOutput| Select-Object -Property CreationDate,UserIds,RecordType,AuditData | Export-Csv -Append -Path "$OutputFolder\$filename" -NoTypeInformation
        }
    } while ($AuditOutput)
    $endDate = $EndDate.AddHours(-3)
} while ($Start -lt $StartDate)

# References
# Modify from https://github.com/cyberisltd/Office-365-Tools/blob/master/unifiedlogsearch.ps1
# https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/exchange-online-powershell-v2/exchange-online-powershell-v2
# https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-audit/search-unifiedauditlog
# https://docs.microsoft.com/en-us/microsoft-365/compliance/search-the-audit-log-in-security-and-compliance
