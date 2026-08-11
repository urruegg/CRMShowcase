BeforeAll {
    . "$PSScriptRoot/../Get-PromotionSmokeResult.ps1"

    function New-Facts {
        [pscustomobject]@{
            ActiveLocales     = @(1033, 1031, 1036, 1040)
            Solutions         = @(
                [pscustomobject]@{ Name = 'crmshow_Foundation'; Version = '1.1.0.0'; IsManaged = $true },
                [pscustomobject]@{ Name = 'crmshow_DataModel';  Version = '1.1.0.0'; IsManaged = $true }
            )
            Tables            = @('crmshow_accountcontactrole','crmshow_policyprojection','crmshow_policypartyrole')
            ReaderCanMutate   = $false
            StewardCanAdmin   = $false
            LocalizedLabels   = $true
        }
    }
}

Describe "Get-PromotionSmokeResult" {
    It "passes when all facts meet expectations" {
        $r = Get-PromotionSmokeResult -Facts (New-Facts) `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole','crmshow_policyprojection','crmshow_policypartyrole')
        $r.Overall | Should -BeTrue
        ($r.Checks | Where-Object { -not $_.Pass }) | Should -BeNullOrEmpty
    }

    It "fails overall when a language is inactive" {
        $facts = New-Facts
        $facts.ActiveLocales = @(1033, 1031, 1036)   # IT missing
        $r = Get-PromotionSmokeResult -Facts $facts `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole')
        $r.Overall | Should -BeFalse
        ($r.Checks | Where-Object { $_.Name -eq 'LanguagesActive' }).Pass | Should -BeFalse
    }

    It "fails when Reader can mutate" {
        $facts = New-Facts
        $facts.ReaderCanMutate = $true
        $r = Get-PromotionSmokeResult -Facts $facts `
            -ExpectedLocales @(1033,1031,1036,1040) `
            -ExpectedSolutions @('crmshow_Foundation','crmshow_DataModel') `
            -ExpectedTables @('crmshow_accountcontactrole')
        ($r.Checks | Where-Object { $_.Name -eq 'ReaderReadOnly' }).Pass | Should -BeFalse
        $r.Overall | Should -BeFalse
    }
}
