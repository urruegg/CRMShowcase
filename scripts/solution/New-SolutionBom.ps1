<#
.SYNOPSIS
    Generate a deterministic bill of materials from an unpacked Dataverse solution.
.DESCRIPTION
    Inventories root components, tables, columns, choices, forms, views,
    relationships, apps, site maps, web resources, bots, and remaining
    component folders. Output contains structural metadata only.
#>
[CmdletBinding()]
param(
    [string]$SourceFolder,
    [string]$MetadataModelFolder,
    [string]$MappingPath,
    [string]$JsonPath,
    [string]$CsvPath
)

function Get-IntakeRelativePath {
    param([string]$Root, [string]$Path)

    $rootPath = (Resolve-Path $Root).Path.TrimEnd('\')
    $fullPath = (Resolve-Path $Path).Path
    return $fullPath.Substring($rootPath.Length).TrimStart('\').Replace('\', '/')
}

function New-BomItem {
    param(
        [string]$ComponentType,
        [string]$LogicalName,
        [string]$DisplayName,
        [string]$SourcePath,
        [string]$Parent = '',
        [string[]]$Dependencies = @(),
        [bool]$RootComponent = $false,
        [string]$DataType = '',
        [string]$RequiredLevel = '',
        [string]$Description = ''
    )

    [pscustomobject][ordered]@{
        componentType = $ComponentType
        logicalName = $LogicalName
        displayName = $DisplayName
        sourcePath = $SourcePath
        parent = $Parent
        dependencies = @($Dependencies)
        rootComponent = $RootComponent
        dataType = $DataType
        requiredLevel = $RequiredLevel
        description = $Description
        domain = 'Unclassified pending review'
        targetSolution = 'None'
        disposition = 'Investigate'
        rationale = 'Pending evidence-based review'
        licenceReview = 'Investigate'
        maturityReview = 'Investigate'
        sourceOnly = $true
    }
}

function Get-FirstXmlValue {
    param($Nodes, [string]$Property, [string]$Attribute)

    foreach ($node in @($Nodes)) {
        if ($Attribute -and $node -is [System.Xml.XmlElement]) {
            $value = $node.GetAttribute($Attribute)
            if ($value) { return [string]$value }
        }
        if ($Property -and $node.$Property) {
            return [string]$node.$Property
        }
    }
    return ''
}

function New-SolutionBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceFolder,
        [string]$MetadataModelFolder
    )

    $root = (Resolve-Path $SourceFolder).Path
    $solutionPath = Join-Path $root 'Other\Solution.xml'
    if (-not (Test-Path $solutionPath)) {
        throw "Solution.xml not found under '$SourceFolder\Other'."
    }

    [xml]$solution = Get-Content $solutionPath -Raw
    $rootTypes = @{
        '1' = 'Entity'
        '20' = 'SecurityRole'
        '29' = 'Workflow'
        '60' = 'Form'
        '61' = 'WebResource'
        '62' = 'SiteMap'
        '80' = 'AppModule'
        '91' = 'PluginAssembly'
        '92' = 'PluginStep'
        '300' = 'CanvasApp'
        '371' = 'Connector'
    }
    $rootComponents = @{}
    foreach ($component in @($solution.ImportExportXml.SolutionManifest.RootComponents.RootComponent)) {
        $typeCode = [string]$component.type
        $typeName = if ($rootTypes.ContainsKey($typeCode)) { $rootTypes[$typeCode] } else { "RootComponent:$typeCode" }
        $schemaName = [string]$component.schemaName
        $rootComponents["$typeName|$($schemaName.ToLowerInvariant())"] = $component
    }

    $items = [System.Collections.Generic.List[object]]::new()
    $seen = @{}
    function Add-UniqueBomItem {
        param($Item)
        $key = "$($Item.componentType)|$($Item.logicalName.ToLowerInvariant())|$($Item.parent.ToLowerInvariant())"
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $items.Add($Item)
        }
    }

    $entitiesPath = Join-Path $root 'Entities'
    if (Test-Path $entitiesPath) {
        foreach ($entityFile in Get-ChildItem $entitiesPath -Filter Entity.xml -Recurse -File | Sort-Object FullName) {
            [xml]$entityXml = Get-Content $entityFile.FullName -Raw
            $logicalName = [string]$entityXml.Entity.Name.'#text'
            if (-not $logicalName) { $logicalName = [string]$entityXml.Entity.EntityInfo.entity.Name }
            $displayName = [string]$entityXml.Entity.Name.LocalizedName
            if (-not $displayName) { $displayName = $logicalName }
            $relativePath = Get-IntakeRelativePath -Root $root -Path $entityFile.FullName
            $isRoot = $rootComponents.ContainsKey("Entity|$($logicalName.ToLowerInvariant())")
            Add-UniqueBomItem (New-BomItem -ComponentType Entity -LogicalName $logicalName -DisplayName $displayName -SourcePath $relativePath -RootComponent $isRoot)

            foreach ($attribute in @($entityXml.Entity.EntityInfo.entity.attributes.attribute)) {
                if (-not $attribute) { continue }
                $attributeName = [string]$attribute.LogicalName
                if (-not $attributeName) { $attributeName = [string]$attribute.Name }
                $attributeDisplay = Get-FirstXmlValue -Nodes $attribute.displaynames.displayname -Attribute description
                $description = Get-FirstXmlValue -Nodes $attribute.Descriptions.Description -Attribute description
                Add-UniqueBomItem (New-BomItem `
                    -ComponentType Attribute `
                    -LogicalName $attributeName `
                    -DisplayName $attributeDisplay `
                    -SourcePath $relativePath `
                    -Parent $logicalName `
                    -DataType ([string]$attribute.Type) `
                    -RequiredLevel ([string]$attribute.RequiredLevel) `
                    -Description $description)

                foreach ($option in @($attribute.optionset.options.option)) {
                    if (-not $option) { continue }
                    $optionValue = [string]$option.value
                    $optionLabel = Get-FirstXmlValue -Nodes $option.labels.label -Attribute description
                    Add-UniqueBomItem (New-BomItem `
                        -ComponentType ChoiceOption `
                        -LogicalName "$attributeName`:$optionValue" `
                        -DisplayName $optionLabel `
                        -SourcePath $relativePath `
                        -Parent "$logicalName.$attributeName")
                }
            }

            $entityFolder = $entityFile.Directory.FullName
            foreach ($formFile in Get-ChildItem (Join-Path $entityFolder 'FormXml') -Filter *.xml -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName) {
                Add-UniqueBomItem (New-BomItem -ComponentType Form -LogicalName $formFile.BaseName -DisplayName $formFile.Directory.Name -SourcePath (Get-IntakeRelativePath $root $formFile.FullName) -Parent $logicalName)
            }
            foreach ($viewFile in Get-ChildItem (Join-Path $entityFolder 'SavedQueries') -Filter *.xml -File -ErrorAction SilentlyContinue | Sort-Object FullName) {
                [xml]$viewXml = Get-Content $viewFile.FullName -Raw
                $viewName = Get-FirstXmlValue -Nodes $viewXml.savedquery.LocalizedNames.LocalizedName -Attribute description
                Add-UniqueBomItem (New-BomItem -ComponentType View -LogicalName $viewFile.BaseName -DisplayName $viewName -SourcePath (Get-IntakeRelativePath $root $viewFile.FullName) -Parent $logicalName)
            }
            $ribbonPath = Join-Path $entityFolder 'RibbonDiff.xml'
            if (Test-Path $ribbonPath) {
                Add-UniqueBomItem (New-BomItem -ComponentType Ribbon -LogicalName "${logicalName}:ribbon" -DisplayName "$displayName ribbon" -SourcePath (Get-IntakeRelativePath $root $ribbonPath) -Parent $logicalName)
            }
        }
    }

    $relationshipsPath = Join-Path $root 'Other\Relationships.xml'
    if (Test-Path $relationshipsPath) {
        [xml]$relationships = Get-Content $relationshipsPath -Raw
        foreach ($relationship in @($relationships.EntityRelationships.EntityRelationship)) {
            $name = [string]$relationship.Name
            Add-UniqueBomItem (New-BomItem -ComponentType Relationship -LogicalName $name -DisplayName $name -SourcePath 'Other/Relationships.xml')
        }
    }

    foreach ($dataFile in Get-ChildItem (Join-Path $root 'WebResources') -Filter *.data.xml -File -ErrorAction SilentlyContinue | Sort-Object FullName) {
        [xml]$webResource = Get-Content $dataFile.FullName -Raw
        $name = [string]$webResource.WebResource.Name
        $displayName = [string]$webResource.WebResource.DisplayName
        $payloadPath = Join-Path $dataFile.Directory.FullName $name
        $sourcePath = if (Test-Path $payloadPath) { Get-IntakeRelativePath $root $payloadPath } else { Get-IntakeRelativePath $root $dataFile.FullName }
        Add-UniqueBomItem (New-BomItem -ComponentType WebResource -LogicalName $name -DisplayName $displayName -SourcePath $sourcePath -RootComponent $rootComponents.ContainsKey("WebResource|$($name.ToLowerInvariant())"))
    }

    $folderComponentTypes = [ordered]@{
        'AppModules' = 'AppModule'
        'AppModuleSiteMaps' = 'SiteMap'
        'bots' = 'Bot'
        'botcomponents' = 'BotComponent'
        'dvtablesearchs' = 'DataverseSearch'
        'dvtablesearchentities' = 'DataverseSearchEntity'
        'organizationsettings' = 'OrganizationSetting'
        'settingdefinitions' = 'SettingDefinition'
    }
    foreach ($folderName in $folderComponentTypes.Keys) {
        $folderPath = Join-Path $root $folderName
        if (-not (Test-Path $folderPath)) { continue }
        foreach ($componentFolder in Get-ChildItem $folderPath -Directory | Sort-Object Name) {
            $componentType = $folderComponentTypes[$folderName]
            $metadataFile = Get-ChildItem $componentFolder.FullName -File | Where-Object { $_.Extension -in @('.xml', '.json') } | Sort-Object Name | Select-Object -First 1
            $sourcePath = if ($metadataFile) { Get-IntakeRelativePath $root $metadataFile.FullName } else { Get-IntakeRelativePath $root $componentFolder.FullName }
            $rootKey = "$componentType|$($componentFolder.Name.ToLowerInvariant())"
            Add-UniqueBomItem (New-BomItem -ComponentType $componentType -LogicalName $componentFolder.Name -DisplayName $componentFolder.Name -SourcePath $sourcePath -RootComponent $rootComponents.ContainsKey($rootKey))
        }
    }

    foreach ($entry in $rootComponents.GetEnumerator()) {
        $parts = $entry.Key.Split('|', 2)
        $key = "$($parts[0])|$($parts[1])|"
        if (-not $seen.ContainsKey($key)) {
            Add-UniqueBomItem (New-BomItem -ComponentType $parts[0] -LogicalName ([string]$entry.Value.schemaName) -DisplayName ([string]$entry.Value.schemaName) -SourcePath 'Other/Solution.xml' -RootComponent $true)
        }
    }

    foreach ($missing in @($solution.ImportExportXml.SolutionManifest.MissingDependencies.MissingDependency)) {
        if (-not $missing) { continue }
        $required = $missing.Required
        $dependent = $missing.Dependent
        $requiredName = [string]$required.schemaName
        if (-not $requiredName) { $requiredName = [string]$required.id }
        if (-not $requiredName) { $requiredName = "type:$([string]$required.type)" }
        $dependentName = [string]$dependent.schemaName
        if (-not $dependentName) { $dependentName = [string]$dependent.id }
        if (-not $dependentName) { $dependentName = [string]$dependent.displayName }
        $requiredDisplay = [string]$required.displayName
        if (-not $requiredDisplay) { $requiredDisplay = $requiredName }
        $requiredSolutions = @()
        if ($required.solution) { $requiredSolutions += [string]$required.solution }
        foreach ($package in @($required.package)) {
            if ($package) { $requiredSolutions += [string]$package.'#text' }
        }
        Add-UniqueBomItem (New-BomItem `
            -ComponentType MissingDependency `
            -LogicalName $requiredName `
            -DisplayName $requiredDisplay `
            -SourcePath 'Other/Solution.xml' `
            -Parent $dependentName `
            -Dependencies ($requiredSolutions | Where-Object { $_ } | Sort-Object -Unique) `
            -Description 'Dependency reported by the Dataverse solution export.')
    }

    if ($MetadataModelFolder -and (Test-Path $MetadataModelFolder)) {
        foreach ($modelFile in Get-ChildItem $MetadataModelFolder -Filter *.cs -File -Recurse | Sort-Object FullName) {
            $content = Get-Content $modelFile.FullName -Raw
            $entityMatch = [regex]::Match($content, 'EntityLogicalNameAttribute\("(?<name>[^"]+)"\)')
            if (-not $entityMatch.Success) { continue }
            $entityName = $entityMatch.Groups['name'].Value
            $attributePattern = 'AttributeLogicalNameAttribute\("(?<logical>[^"]+)"\)\]\s+(?:\[[^\]]+\]\s+)*public\s+(?:virtual\s+|override\s+)?(?<type>[^\s]+(?:<[^>]+>)?)\s+(?<property>\w+)'
            foreach ($match in [regex]::Matches($content, $attributePattern)) {
                $logicalName = $match.Groups['logical'].Value
                $propertyName = $match.Groups['property'].Value
                $dataType = $match.Groups['type'].Value
                Add-UniqueBomItem (New-BomItem `
                    -ComponentType Attribute `
                    -LogicalName $logicalName `
                    -DisplayName $propertyName `
                    -SourcePath "metadata:DataverseModelBuilder/$entityName" `
                    -Parent $entityName `
                    -DataType $dataType `
                    -Description 'Enriched from live Dataverse table metadata because the solution package omitted the definition.')
            }
            $relationshipPattern = 'RelationshipSchemaNameAttribute\("(?<name>[^"]+)"\)'
            foreach ($match in [regex]::Matches($content, $relationshipPattern)) {
                $relationshipName = $match.Groups['name'].Value
                Add-UniqueBomItem (New-BomItem `
                    -ComponentType Relationship `
                    -LogicalName $relationshipName `
                    -DisplayName $relationshipName `
                    -SourcePath "metadata:DataverseModelBuilder/$entityName" `
                    -Parent $entityName `
                    -Description 'Enriched from live Dataverse table metadata because the solution package omitted the definition.')
            }
        }
    }

    return @($items | Sort-Object componentType, parent, logicalName)
}

if ($SourceFolder) {
    $result = New-SolutionBom -SourceFolder $SourceFolder -MetadataModelFolder $MetadataModelFolder
    if ($MappingPath) {
        $mapping = Import-Csv $MappingPath
        $mappingByKey = @{}
        foreach ($row in $mapping) {
            $key = '{0}|{1}|{2}' -f $row.componentType, $row.logicalName, $row.parent
            $mappingByKey[$key] = $row
        }
        foreach ($item in $result) {
            $key = '{0}|{1}|{2}' -f $item.componentType, $item.logicalName, $item.parent
            if (-not $mappingByKey.ContainsKey($key)) {
                throw "Domain mapping missing BOM item '$key'."
            }
            $row = $mappingByKey[$key]
            $item.domain = $row.domain
            $item.targetSolution = $row.targetSolution
            $item.disposition = $row.disposition
            $item.rationale = $row.rationale
            $item.licenceReview = $row.licenceReview
            $item.maturityReview = $row.maturityReview
        }
    }
    if ($JsonPath) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $JsonPath) | Out-Null
        $result | ConvertTo-Json -Depth 8 | Set-Content -Path $JsonPath -Encoding UTF8
    }
    if ($CsvPath) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CsvPath) | Out-Null
        $result |
            Select-Object componentType, logicalName, displayName, sourcePath, parent,
                @{ Name = 'dependencies'; Expression = { $_.dependencies -join ';' } },
                rootComponent, dataType, requiredLevel, description, domain,
                targetSolution, disposition, rationale, licenceReview,
                maturityReview, sourceOnly |
            Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    }
    $result
}
