BeforeAll {
    . "$PSScriptRoot/../Test-BreakingChange.ps1"
}

Describe "Test-BreakingChange" {
    It "classifies removed attribute as major (breaking)" {
        $diff = @'
--- a/solutions/CRMShow.Core/Entities/account/Entity.xml
+++ b/solutions/CRMShow.Core/Entities/account/Entity.xml
@@
-      <attribute PhysicalName="crmshow_legacyid" />
       <attribute PhysicalName="crmshow_ownerid" />
'@
        Test-BreakingChange -Diff $diff | Should -Be 'major'
    }

    It "classifies removed entity as major (breaking)" {
        $diff = @'
--- a/solutions/CRMShow.Core/Other/Solution.xml
+++ b/solutions/CRMShow.Core/Other/Solution.xml
@@
-      <entity>crmshow_legacyaccount</entity>
       <entity>crmshow_account</entity>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'major'
    }

    It "classifies added attribute as minor (additive)" {
        $diff = @'
--- a/solutions/CRMShow.Core/Entities/account/Entity.xml
+++ b/solutions/CRMShow.Core/Entities/account/Entity.xml
@@
       <attribute PhysicalName="crmshow_ownerid" />
+      <attribute PhysicalName="crmshow_riskscore" />
'@
        Test-BreakingChange -Diff $diff | Should -Be 'minor'
    }

    It "classifies added entity as minor (additive)" {
        $diff = @'
--- a/solutions/CRMShow.Core/Other/Solution.xml
+++ b/solutions/CRMShow.Core/Other/Solution.xml
@@
       <entity>crmshow_account</entity>
+      <entity>crmshow_engagementevent</entity>
'@
        Test-BreakingChange -Diff $diff | Should -Be 'minor'
    }

    It "classifies whitespace/label-only edits as patch" {
        $diff = @'
--- a/solutions/CRMShow.Core/Entities/account/Entity.xml
+++ b/solutions/CRMShow.Core/Entities/account/Entity.xml
@@
-      <LocalizedLabel description="Account" languagecode="1033" />
+      <LocalizedLabel description="Customer Account" languagecode="1033" />
'@
        Test-BreakingChange -Diff $diff | Should -Be 'patch'
    }

    It "classifies an empty solution diff as patch" {
        Test-BreakingChange -Diff '' | Should -Be 'patch'
    }
}
