$ErrorActionPreference = 'Stop'

$root = 'REPO_ROOT'
$sampleDir = Join-Path $root '_work\sample_doc_unzipped'
$invoiceFlowRoot = Join-Path $root '_work\iflow_invoice_doc'
$routeIdocFlowRoot = Join-Path $root '_work\doc_flows\RouteIdocs'
$replicateMaterialFlowRoot = Join-Path $root '_work\doc_flows\ReplicateMaterial'
$materialExitFlowRoot = Join-Path $root '_work\doc_flows\MaterialExit'
$replicateB2BCustomerFlowRoot = Join-Path $root '_work\doc_flows\ReplicateB2BCustomer'
$accessDataStoreFlowRoot = Join-Path $root '_work\doc_flows_more\Access DataStore for S4HANA _1_'
$fetchTokenFlowRoot = Join-Path $root '_work\doc_flows_more\IF_CI_TO_S4_FetchToken'
$getInventoryReportFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInventoryReport'
$getInvoiceListFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoiceList'
$getInvoiceDetailsFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoiceDetails'
$getInvoicePDFFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoicePDF'
$getJobQuoteDetailsFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetJobQuoteDetails'
$getJobQuoteListFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetJobQuoteList'
$listingsAndExclusionsFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_ListingsAndExclusions'
$manageSalesOrdersFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_ManageSalesOrders'
$materialStockFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_MaterialStock'
$orderSimulateFlowRoot = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_OrderSimulate'
$communicationPreferencesFlowRoot = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_CommunicationPreferences'
$salesKitsFlowRoot = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits'
$salesKitsManualTriggerFlowRoot = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits_ManualTrigger'
$salesKitsScheduledTriggerFlowRoot = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits_ScheduledTrigger'
$outputDir = Join-Path $root 'generated_docs'
$tempDir = Join-Path $outputDir 'tmp_toto_doc_from_template'
$outputDoc = Join-Path $outputDir 'TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation.docx'
$outputZip = Join-Path $outputDir 'TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation.zip'

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
Copy-Item -Recurse -Force $sampleDir $tempDir

function Read-JavaProperties {
    param([string]$Path)

    $result = [ordered]@{}
    foreach ($line in Get-Content -Path $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.TrimStart().StartsWith('#')) { continue }

        $match = [regex]::Match($line, '^(?<key>(?:\\.|[^=])*)=(?<value>.*)$')
        if (-not $match.Success) { continue }

        $key = $match.Groups['key'].Value `
            -replace '\\ ', ' ' `
            -replace '\\=', '=' `
            -replace '\\:', ':' `
            -replace '\\\\', '\'

        $value = $match.Groups['value'].Value `
            -replace '\\ ', ' ' `
            -replace '\\=', '=' `
            -replace '\\:', ':' `
            -replace '\\\\', '\'

        $result[$key] = $value
    }

    return $result
}

function Get-ExternalizedParameterKeys {
    param([string]$Path)

    [xml]$xml = Get-Content -Raw -Path $Path
    $keys = New-Object System.Collections.ArrayList
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($parameter in $xml.parameters.parameter) {
        $candidate = ''
        if ($parameter.name) {
            $candidate = [string]$parameter.name
        } elseif ($parameter.key) {
            $candidate = [string]$parameter.key
        }

        $candidate = $candidate.Trim()
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and $seen.Add($candidate)) {
            [void]$keys.Add($candidate)
        }
    }

    foreach ($reference in $xml.parameters.param_references.reference) {
        if ($reference.param_key) {
            $candidate = ([string]$reference.param_key).Trim()
            if (-not [string]::IsNullOrWhiteSpace($candidate) -and $seen.Add($candidate)) {
                [void]$keys.Add($candidate)
            }
        }
    }

    return ,($keys.ToArray())
}

function Get-BundleVersion {
    param([string]$ArtifactRoot)

    $manifestPath = Join-Path $ArtifactRoot 'META-INF\MANIFEST.MF'
    foreach ($line in Get-Content -Path $manifestPath) {
        if ($line -like 'Bundle-Version:*') {
            return ($line -replace '^Bundle-Version:\s*', '').Trim()
        }
    }
    return ''
}

function Get-ConfiguredExternalizedRows {
    param([string]$ArtifactRoot)

    $props = Read-JavaProperties -Path (Join-Path $ArtifactRoot 'src\main\resources\parameters.prop')
    $keys = Get-ExternalizedParameterKeys -Path (Join-Path $ArtifactRoot 'src\main\resources\parameters.propdef')
    $rows = New-Object System.Collections.ArrayList
    foreach ($key in $keys) {
        if ($props.Contains($key)) {
            [void]$rows.Add([object[]]@($key, [string]$props[$key]))
        }
    }
    return ,($rows.ToArray())
}

function Get-ConfiguredPropertyValue {
    param(
        [string]$ArtifactRoot,
        [string]$Key
    )

    $props = Read-JavaProperties -Path (Join-Path $ArtifactRoot 'src\main\resources\parameters.prop')
    return [string]$props[$Key]
}

function Get-ConfiguredCredentialRows {
    param([string]$ArtifactRoot)

    $propsPath = Join-Path $ArtifactRoot 'src\main\resources\parameters.prop'
    if (-not (Test-Path $propsPath)) {
        return @()
    }

    $props = Read-JavaProperties -Path $propsPath
    $propDefPath = Join-Path $ArtifactRoot 'src\main\resources\parameters.propdef'
    $externalizedKeys = @()
    if (Test-Path $propDefPath) {
        $externalizedKeys = @(Get-ExternalizedParameterKeys -Path $propDefPath)
    }

    $candidateKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $props.Keys) {
        if ($key -match '(?i)credential|credentials|oauth') {
            [void]$candidateKeys.Add([string]$key)
        }
    }
    foreach ($key in $externalizedKeys) {
        if ($key -match '(?i)credential|credentials|oauth') {
            [void]$candidateKeys.Add([string]$key)
        }
    }

    $rows = New-Object System.Collections.ArrayList
    foreach ($key in @($candidateKeys | Sort-Object)) {
        $value = [string]$props[$key]
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            [void]$rows.Add([pscustomobject]@{
                Key = [string]$key
                Value = $value.Trim()
            })
        }
    }

    return ,($rows.ToArray())
}

function Get-AuthenticationGroupDefinition {
    param(
        [string]$Direction,
        [string]$CredentialKey,
        [string]$CredentialValue
    )

    $classificationText = (($CredentialKey + ' ' + $CredentialValue).Trim())

    if ($classificationText -match '(?i)S/4HANA|(^|[^A-Za-z])S4([^A-Za-z]|$)|US_S4') {
        return [pscustomobject]@{
            Key = 'S4'
            Component = 'SAP Integration Suite to SAP S/4HANA'
            Direction = 'Outbound from SAP Integration Suite'
        }
    }

    if ($classificationText -match '(?i)Commerce|S1_') {
        return [pscustomobject]@{
            Key = 'Commerce'
            Component = 'SAP Integration Suite to SAP Commerce Cloud'
            Direction = 'Outbound from SAP Integration Suite'
        }
    }

    if ([string]::IsNullOrWhiteSpace($Direction)) {
        return $null
    }

    if ($Direction -match 'to SAP S/4HANA') {
        return [pscustomobject]@{
            Key = 'S4'
            Component = 'SAP Integration Suite to SAP S/4HANA'
            Direction = 'Outbound from SAP Integration Suite'
        }
    }

    if ($Direction -match 'to SAP Commerce Cloud') {
        return [pscustomobject]@{
            Key = 'Commerce'
            Component = 'SAP Integration Suite to SAP Commerce Cloud'
            Direction = 'Outbound from SAP Integration Suite'
        }
    }

    if ($Direction -match '(?i)internal') {
        return [pscustomobject]@{
            Key = 'Internal'
            Component = 'Internal within SAP Integration Suite'
            Direction = 'Internal processing'
        }
    }

    return $null
}

function New-FlowEntry {
    param(
        [string]$GroupTitle,
        [string]$GroupIntro,
        [string[]]$GroupListItems,
        [string]$GroupClosing,
        [string]$Title,
        [string]$ArtifactRoot,
        [string]$EndpointLabel,
        [string]$EndpointKey,
        [string]$Description,
        [string]$Direction,
        [string]$Object,
        [string]$Purpose,
        [string]$Implementation
    )

    if ([string]::IsNullOrWhiteSpace($Direction) -and -not [string]::IsNullOrWhiteSpace($Description)) {
        $normalizedDescription = ($Description -replace '\s+', ' ').Trim()
        $match = [regex]::Match($normalizedDescription, 'Direction:\s*(?<Direction>.*?)\s+Object:\s*(?<Object>.*?)\s+Purpose:\s*(?<Purpose>.*?)\s+Implementation:\s*(?<Implementation>.*)$')
        if ($match.Success) {
            $Direction = $match.Groups['Direction'].Value.Trim()
            $Object = $match.Groups['Object'].Value.Trim()
            $Purpose = $match.Groups['Purpose'].Value.Trim()
            $Implementation = $match.Groups['Implementation'].Value.Trim()
        }
    }

    return [pscustomobject]@{
        GroupTitle = $GroupTitle
        GroupIntro = $GroupIntro
        GroupListItems = $GroupListItems
        GroupClosing = $GroupClosing
        Title = $Title
        ArtifactRoot = $ArtifactRoot
        EndpointLabel = $EndpointLabel
        EndpointValue = Get-ConfiguredPropertyValue -ArtifactRoot $ArtifactRoot -Key $EndpointKey
        Direction = $Direction
        Object = $Object
        Purpose = $Purpose
        Implementation = $Implementation
        Version = Get-BundleVersion -ArtifactRoot $ArtifactRoot
        ExternalizedRows = Get-ConfiguredExternalizedRows -ArtifactRoot $ArtifactRoot
        CredentialRows = Get-ConfiguredCredentialRows -ArtifactRoot $ArtifactRoot
    }
}

[xml]$docXml = Get-Content -Raw -Path (Join-Path $tempDir 'word\document.xml')
$nsUri = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$ns = New-Object System.Xml.XmlNamespaceManager($docXml.NameTable)
$ns.AddNamespace('w', $nsUri)
$body = $docXml.SelectSingleNode('/w:document/w:body', $ns)

function Get-ParagraphText {
    param($Paragraph)
    return ((@($Paragraph.SelectNodes('.//w:t', $ns)) | ForEach-Object { $_.InnerText }) -join '') -replace '\s+', ' ' -replace [char]160, ' '
}

function Get-StyleId {
    param($Paragraph)
    $styleNode = $Paragraph.SelectSingleNode('./w:pPr/w:pStyle', $ns)
    if ($styleNode -eq $null) { return '' }
    return $styleNode.GetAttribute('val', $nsUri)
}

function Get-FirstRunPrClone {
    param($Paragraph)
    $runPr = $Paragraph.SelectSingleNode('.//w:r/w:rPr', $ns)
    if ($runPr -eq $null) { return $null }
    return $runPr.CloneNode($true)
}

function Set-ParagraphText {
    param(
        $Paragraph,
        [string]$Text
    )

    $runPrClone = Get-FirstRunPrClone -Paragraph $Paragraph
    $childrenToRemove = @()
    foreach ($child in @($Paragraph.ChildNodes)) {
        if ($child.LocalName -notin @('pPr', 'bookmarkStart', 'bookmarkEnd')) {
            $childrenToRemove += $child
        }
    }
    foreach ($child in $childrenToRemove) {
        [void]$Paragraph.RemoveChild($child)
    }

    $run = $docXml.CreateElement('w', 'r', $nsUri)
    if ($runPrClone -ne $null) {
        [void]$run.AppendChild($docXml.ImportNode($runPrClone, $true))
    }

    $textNode = $docXml.CreateElement('w', 't', $nsUri)
    if ($Text.StartsWith(' ') -or $Text.EndsWith(' ')) {
        $attr = $docXml.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace')
        $attr.Value = 'preserve'
        [void]$textNode.Attributes.Append($attr)
    }
    $textNode.InnerText = $Text
    [void]$run.AppendChild($textNode)
    [void]$Paragraph.AppendChild($run)
}

function Set-CellText {
    param(
        $Cell,
        [string]$Text
    )

    $templateParagraph = $Cell.SelectSingleNode('./w:p[1]', $ns)
    if ($templateParagraph -ne $null) {
        $paragraph = $templateParagraph.CloneNode($true)
    }
    else {
        $paragraph = $docXml.CreateElement('w', 'p', $nsUri)
    }

    $childrenToRemove = @()
    foreach ($child in @($Cell.ChildNodes)) {
        if ($child.LocalName -ne 'tcPr') {
            $childrenToRemove += $child
        }
    }
    foreach ($child in $childrenToRemove) {
        [void]$Cell.RemoveChild($child)
    }

    [void]$Cell.AppendChild($paragraph)
    Set-ParagraphText -Paragraph $paragraph -Text $Text
}

function Find-Paragraph {
    param(
        [string]$TextContains,
        [string]$StyleId = '',
        [int]$Occurrence = 1
    )

    $count = 0
    foreach ($paragraph in @($docXml.SelectNodes('//w:p', $ns))) {
        $text = (Get-ParagraphText -Paragraph $paragraph).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        if ($text -notlike "*$TextContains*") { continue }
        if ($StyleId -and (Get-StyleId -Paragraph $paragraph) -ne $StyleId) { continue }
        $count++
        if ($count -eq $Occurrence) {
            return $paragraph
        }
    }
    throw "Paragraph not found: $TextContains ($StyleId)"
}

function Find-FirstParagraphByStyle {
    param(
        [string]$StyleId,
        [string]$TextMustContain = ''
    )

    foreach ($paragraph in @($docXml.SelectNodes('//w:p', $ns))) {
        $text = (Get-ParagraphText -Paragraph $paragraph).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        if ((Get-StyleId -Paragraph $paragraph) -ne $StyleId) { continue }
        if ($TextMustContain -and $text -notlike "*$TextMustContain*") { continue }
        return $paragraph
    }
    throw "Paragraph style not found: $StyleId"
}

function Find-NextParagraphAfter {
    param(
        $Node,
        [string]$StyleId = '',
        [switch]$RequireText
    )

    $candidate = Get-NextElementSibling -Node $Node
    while ($candidate -ne $null) {
        if ($candidate.LocalName -eq 'p') {
            $text = (Get-ParagraphText -Paragraph $candidate).Trim()
            if ($RequireText -and [string]::IsNullOrWhiteSpace($text)) {
                $candidate = Get-NextElementSibling -Node $candidate
                continue
            }
            if ($StyleId -and (Get-StyleId -Paragraph $candidate) -ne $StyleId) {
                $candidate = Get-NextElementSibling -Node $candidate
                continue
            }
            return $candidate
        }
        $candidate = Get-NextElementSibling -Node $candidate
    }
    throw 'Following paragraph not found.'
}

function Get-NextElementSibling {
    param($Node)
    $candidate = $Node.NextSibling
    while ($candidate -ne $null -and $candidate.NodeType -ne [System.Xml.XmlNodeType]::Element) {
        $candidate = $candidate.NextSibling
    }
    return $candidate
}

function Find-NextTableAfter {
    param($Node)
    $candidate = Get-NextElementSibling -Node $Node
    while ($candidate -ne $null) {
        if ($candidate.LocalName -eq 'tbl') { return $candidate }
        $candidate = Get-NextElementSibling -Node $candidate
    }
    throw "No following table found."
}

function Remove-NodesBetween {
    param(
        $StartNode,
        $EndNode
    )

    $candidate = Get-NextElementSibling -Node $StartNode
    while ($candidate -ne $null -and -not [object]::ReferenceEquals($candidate, $EndNode)) {
        $next = Get-NextElementSibling -Node $candidate
        [void]$body.RemoveChild($candidate)
        $candidate = $next
    }
}

function Clone-ParagraphWithText {
    param(
        $TemplateParagraph,
        [string]$Text
    )

    $clone = $TemplateParagraph.CloneNode($true)
    Set-ParagraphText -Paragraph $clone -Text $Text
    return $clone
}

function Clear-ParagraphContent {
    param($Paragraph)

    $childrenToRemove = @()
    foreach ($child in @($Paragraph.ChildNodes)) {
        if ($child.LocalName -notin @('pPr', 'bookmarkStart', 'bookmarkEnd')) {
            $childrenToRemove += $child
        }
    }
    foreach ($child in $childrenToRemove) {
        [void]$Paragraph.RemoveChild($child)
    }
}

function Add-RunToParagraph {
    param(
        $Paragraph,
        [string]$Text,
        [bool]$Bold = $false,
        [bool]$BreakAfter = $false,
        $BaseRunPr = $null
    )

    $run = $docXml.CreateElement('w', 'r', $nsUri)
    $effectiveBaseRunPr = if ($BaseRunPr -ne $null) { $BaseRunPr } else { Get-FirstRunPrClone -Paragraph $Paragraph }
    if ($effectiveBaseRunPr -ne $null) {
        $runPr = $docXml.ImportNode($effectiveBaseRunPr, $true)
    }
    else {
        $runPr = $docXml.CreateElement('w', 'rPr', $nsUri)
    }

    if ($Bold) {
        if ($runPr.SelectSingleNode('./w:b', $ns) -eq $null) {
            [void]$runPr.AppendChild($docXml.CreateElement('w', 'b', $nsUri))
        }
        if ($runPr.SelectSingleNode('./w:bCs', $ns) -eq $null) {
            [void]$runPr.AppendChild($docXml.CreateElement('w', 'bCs', $nsUri))
        }
    }

    [void]$run.AppendChild($runPr)

    $textNode = $docXml.CreateElement('w', 't', $nsUri)
    if ($Text.StartsWith(' ') -or $Text.EndsWith(' ')) {
        $attr = $docXml.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace')
        $attr.Value = 'preserve'
        [void]$textNode.Attributes.Append($attr)
    }
    $textNode.InnerText = $Text
    [void]$run.AppendChild($textNode)

    if ($BreakAfter) {
        [void]$run.AppendChild($docXml.CreateElement('w', 'br', $nsUri))
    }

    [void]$Paragraph.AppendChild($run)
}

function Clone-DescriptionParagraph {
    param(
        $TemplateParagraph,
        [string]$Direction,
        [string]$Object,
        [string]$Purpose,
        [string]$Implementation
    )

    $clone = $TemplateParagraph.CloneNode($true)
    $baseRunPr = Get-FirstRunPrClone -Paragraph $clone
    Clear-ParagraphContent -Paragraph $clone

    Add-RunToParagraph -Paragraph $clone -Text 'Description' -Bold $true -BreakAfter $true -BaseRunPr $baseRunPr
    Add-RunToParagraph -Paragraph $clone -Text ('Direction: ' + $Direction) -BreakAfter $true -BaseRunPr $baseRunPr
    Add-RunToParagraph -Paragraph $clone -Text ('Object: ' + $Object) -BreakAfter $true -BaseRunPr $baseRunPr

    if (-not [string]::IsNullOrWhiteSpace($Purpose)) {
        Add-RunToParagraph -Paragraph $clone -Text ('Purpose: ' + $Purpose) -BreakAfter $true -BaseRunPr $baseRunPr
    }

    Add-RunToParagraph -Paragraph $clone -Text ('Implementation: ' + $Implementation) -BaseRunPr $baseRunPr
    return $clone
}

function Ensure-RowCellCount {
    param(
        $Row,
        [int]$DesiredCount
    )

    $cells = @($Row.SelectNodes('./w:tc', $ns))
    if ($cells.Count -eq 0) { throw 'Table row has no cells.' }

    while ($cells.Count -gt $DesiredCount) {
        [void]$Row.RemoveChild($cells[$cells.Count - 1])
        $cells = @($Row.SelectNodes('./w:tc', $ns))
    }

    while ($cells.Count -lt $DesiredCount) {
        $newCell = $cells[$cells.Count - 1].CloneNode($true)
        [void]$Row.AppendChild($newCell)
        $cells = @($Row.SelectNodes('./w:tc', $ns))
    }

    return $cells
}

function Set-TableData {
    param(
        $Table,
        [string[]]$Headers,
        [object[]]$Rows
    )

    $tableRows = @($Table.SelectNodes('./w:tr', $ns))
    if ($tableRows.Count -lt 1) { throw 'Template table has no rows.' }

    $headerRow = $tableRows[0]
    $dataTemplate = if ($tableRows.Count -ge 2) { $tableRows[1].CloneNode($true) } else { $headerRow.CloneNode($true) }

    for ($i = $tableRows.Count - 1; $i -ge 1; $i--) {
        [void]$Table.RemoveChild($tableRows[$i])
    }

    $headerCells = Ensure-RowCellCount -Row $headerRow -DesiredCount $Headers.Count
    for ($i = 0; $i -lt $Headers.Count; $i++) {
        Set-CellText -Cell $headerCells[$i] -Text $Headers[$i]
    }

    if ($Rows.Count -gt 0 -and $Rows[0] -isnot [System.Array]) {
        $Rows = ,$Rows
    }

    foreach ($rowData in $Rows) {
        $row = $dataTemplate.CloneNode($true)
        $cells = Ensure-RowCellCount -Row $row -DesiredCount $Headers.Count
        for ($i = 0; $i -lt $Headers.Count; $i++) {
            $value = if ($i -lt $rowData.Count) { [string]$rowData[$i] } else { '' }
            Set-CellText -Cell $cells[$i] -Text $value
        }
        [void]$Table.AppendChild($row)
    }
}

function Find-TableByHeaderText {
    param([string]$HeaderText)

    foreach ($table in @($docXml.SelectNodes('//w:tbl', $ns))) {
        $firstRow = $table.SelectSingleNode('./w:tr[1]', $ns)
        if ($firstRow -eq $null) { continue }
        $cells = @($firstRow.SelectNodes('./w:tc', $ns))
        foreach ($cell in $cells) {
            $text = ((@($cell.SelectNodes('.//w:t', $ns)) | ForEach-Object { $_.InnerText }) -join '') -replace '\s+', ' '
            if ($text -like "*$HeaderText*") {
                return $table
            }
        }
    }
    throw "Table header not found: $HeaderText"
}

function Add-NodesBefore {
    param(
        $ReferenceNode,
        [object[]]$Nodes
    )
    foreach ($node in $Nodes) {
        [void]$body.InsertBefore($node, $ReferenceNode)
    }
}

$documentDescriptionHeading = Find-Paragraph -TextContains 'Document Description' -StyleId 'Heading1'
$designHeading = Find-Paragraph -TextContains 'Design' -StyleId 'Heading1'
$implementationHeading = Find-Paragraph -TextContains 'Implementation/Integration Details' -StyleId 'Heading1'
$valueMappingsHeading = Find-Paragraph -TextContains 'Value mappings' -StyleId 'Heading2'

$bodyTemplateParagraph = Find-NextParagraphAfter -Node $documentDescriptionHeading -RequireText
$heading2Template = Find-FirstParagraphByStyle -StyleId 'Heading2'
$heading3Template = Find-FirstParagraphByStyle -StyleId 'Heading3'
$listParagraphTemplate = Find-FirstParagraphByStyle -StyleId 'ListParagraph'
$captionTemplate = Find-FirstParagraphByStyle -StyleId 'Caption'
$parameterTableTemplate = Find-TableByHeaderText -HeaderText 'Parameter name'

$flowEntries = @(
    (New-FlowEntry -GroupTitle 'Product replication' -GroupIntro 'This section describes the SAP S/4HANA to SAP Commerce Cloud product replication setup. In the current landscape the end-to-end process consists of an inbound routing flow, the main SAP standard material replication flow, and a dedicated extension flow where project-specific customization is implemented according to SAP best practices.' -GroupListItems @('Route Idocs From S4HANA To SAP Commerce Cloud', 'Replicate Material From S4HANA To SAP Commerce Cloud', 'Process Customized Material Pre Post Exits for S4HANA') -GroupClosing 'The sections below contain information, descriptions of purpose and configuration parameters relevant to these processes.' -Title 'Route Idocs From S4HANA To SAP Commerce Cloud' -ArtifactRoot $routeIdocFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'ODATA-ENTRY' -Description 'Direction: SAP S/4HANA to SAP Commerce Cloud through SAP Integration Suite. Object: business IDoc messages, primarily material master IDocs in the documented scope. Purpose: route incoming IDoc payloads to the appropriate downstream integration flow. Implementation: an IDoc SOAP sender endpoint receives the message, determines the IDoc type, logs unsupported content where required, and forwards supported messages to the relevant ProcessDirect target flow.'),
    (New-FlowEntry -GroupTitle 'Product replication' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'Replicate Material From S4HANA To SAP Commerce Cloud' -ArtifactRoot $replicateMaterialFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'MATERIAL-IFLOW' -Description 'Direction: SAP S/4HANA to SAP Commerce Cloud. Object: material master data, product features, variant data, and related classification content. Purpose: replicate product-related master data from SAP S/4HANA into SAP Commerce Cloud. Implementation: SAP standard integration content is reused as the main processing flow; the incoming material message is transformed and distributed to multiple Commerce OData services, while dedicated extension hooks are available for project-specific behavior.'),
    (New-FlowEntry -GroupTitle 'Product replication' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'Process Customized Material Pre Post Exits for S4HANA' -ArtifactRoot $materialExitFlowRoot -EndpointLabel 'Endpoint (ProcessDirect)' -EndpointKey 'material_post_exits' -Description 'Direction: internal extension processing within the SAP S/4HANA to SAP Commerce Cloud material replication setup. Object: material replication payloads and related enrichment data. Purpose: apply project-specific preprocessing, enrichment, and post-processing for material replication. Implementation: the flow is called from the main material replication iFlow via ProcessDirect and contains the project-specific customization logic, including lookups and mapping enhancements that are intentionally separated from the SAP standard content.'),

    (New-FlowEntry -GroupTitle 'Sales kits replication' -GroupIntro 'This section describes the sales kits replication setup. The documented process consists of one main replication flow and two trigger flows. The main flow performs the actual data retrieval and replication, while the manual and scheduled trigger flows are used to start the process under different operational scenarios.' -GroupListItems @('IF_S4_TO_Commerce_SalesKits', 'IF_S4_TO_Commerce_SalesKits_ManualTrigger', 'IF_S4_TO_Commerce_SalesKits_ScheduledTrigger') -GroupClosing 'The sections below contain information, descriptions of purpose and configuration parameters relevant to these processes.' -Title 'IF_S4_TO_Commerce_SalesKits' -ArtifactRoot $salesKitsFlowRoot -EndpointLabel 'Endpoint (ProcessDirect)' -EndpointKey 'Sender address' -Description 'Direction: SAP S/4HANA to SAP Commerce Cloud. Object: sales kits derived from bill of material data. Purpose: replicate sales kits from SAP S/4HANA into SAP Commerce Cloud. Implementation: the main process is triggered through ProcessDirect, retrieves source data from SAP S/4HANA through OData, and sends the resulting data to SAP Commerce Cloud through OData-based inbound services.'),
    (New-FlowEntry -GroupTitle 'Sales kits replication' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_S4_TO_Commerce_SalesKits_ManualTrigger' -ArtifactRoot $salesKitsManualTriggerFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud or an operational caller to SAP Integration Suite internal processing. Object: sales kits replication trigger requests. Purpose: provide an on-demand trigger for the sales kits replication process. Implementation: an HTTPS sender endpoint receives the trigger request and forwards it to the main sales kits replication flow through ProcessDirect.'),
    (New-FlowEntry -GroupTitle 'Sales kits replication' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_S4_TO_Commerce_SalesKits_ScheduledTrigger' -ArtifactRoot $salesKitsScheduledTriggerFlowRoot -EndpointLabel 'Trigger target (ProcessDirect)' -EndpointKey 'Receiver address' -Description 'Direction: scheduled internal trigger within SAP Integration Suite. Object: sales kits replication trigger requests. Purpose: provide an optional scheduled execution mechanism for the sales kits replication process. Implementation: a timer-based flow starts the main sales kits replication flow through ProcessDirect. According to the provided project note, this option is currently not in active use but is retained for future operational needs.'),

    (New-FlowEntry -GroupTitle 'Customer replication' -GroupIntro 'This section describes the SAP S/4HANA to SAP Commerce Cloud replication of B2B customer-related master data. The documented process covers the main inbound business partner replication flow and the creation or update of the required target entities in SAP Commerce Cloud.' -GroupListItems @('Replicate B2B Customer From S4HANA To SAP Commerce Cloud_Modified') -GroupClosing 'The section below contains information, descriptions of purpose and configuration parameters relevant to this process.' -Title 'Replicate B2B Customer From S4HANA To SAP Commerce Cloud_Modified' -ArtifactRoot $replicateB2BCustomerFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 's4hana_bp_url' -Description 'Direction: SAP S/4HANA to SAP Commerce Cloud. Object: B2B customers, B2B units, addresses, and related business partner relationships. Purpose: replicate customer master data required for B2B commerce scenarios. Implementation: a SOAP interface receives the business partner replication request from SAP S/4HANA, the payload is split and transformed, SAP Commerce Cloud OData services are called to create or update the target entities, and optional ProcessDirect exits are available for project-specific enhancements.'),

    (New-FlowEntry -GroupTitle 'Communication preference retrieval' -GroupIntro 'This section describes the process used to retrieve communication preference information from SAP Commerce Cloud for consumption from the SAP S/4HANA side of the landscape.' -GroupListItems @('IF_S4_TO_Commerce_CommunicationPreferences') -GroupClosing 'The section below contains information, descriptions of purpose and configuration parameters relevant to this process.' -Title 'IF_S4_TO_Commerce_CommunicationPreferences' -ArtifactRoot $communicationPreferencesFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender adapter' -Description 'Direction: SAP S/4HANA to SAP Commerce Cloud. Object: communication preference information. Purpose: retrieve communication preference data maintained in SAP Commerce Cloud. Implementation: SAP Integration Suite exposes an inbound HTTPS endpoint and forwards the request to SAP Commerce Cloud through an HTTP receiver channel using the configured OAuth credential alias.'),

    (New-FlowEntry -GroupTitle 'Access DataStore utility' -GroupIntro 'This section documents the shared utility flow used to access Cloud Integration datastore content in a standardized and reusable way.' -GroupListItems @('Access DataStore for S4HANA') -GroupClosing 'The section below contains information, descriptions of purpose and configuration parameters relevant to this process.' -Title 'Access DataStore for S4HANA' -ArtifactRoot $accessDataStoreFlowRoot -EndpointLabel 'Endpoint (ProcessDirect)' -EndpointKey 'DATASTORE-ACCESS-IFLOW' -Description 'Direction: internal utility processing within SAP Integration Suite. Object: Cloud Integration datastore entries. Purpose: provide a reusable utility that allows other integration flows to access datastore content more efficiently and in a standardized way. Implementation: the utility is exposed through ProcessDirect so that business and technical flows can call it without duplicating datastore-specific handling logic.'),

    (New-FlowEntry -GroupTitle 'Token management utility' -GroupIntro 'This section documents the shared technical utility used to retrieve and cache authentication-related tokens for reuse across business processes.' -GroupListItems @('IF_CI_TO_S4_FetchToken') -GroupClosing 'The section below contains information, descriptions of purpose and configuration parameters relevant to this process.' -Title 'IF_CI_TO_S4_FetchToken' -ArtifactRoot $fetchTokenFlowRoot -EndpointLabel 'Configured S/4 endpoint' -EndpointKey 'S4_ENDPOINT' -Description 'Direction: SAP Integration Suite to SAP S/4HANA. Object: CSRF tokens and session cookies for SAP S/4HANA OData APIs. Purpose: periodically retrieve reusable token information so that business processes can avoid performing token retrieval during each call. Implementation: the flow calls SAP S/4HANA with configured credentials, retrieves the required token information, and stores it for reuse by other processes.'),

    (New-FlowEntry -GroupTitle 'Product and assortment queries' -GroupIntro 'This section describes SAP Commerce Cloud initiated processes that retrieve product, assortment, stock, or reporting information from SAP S/4HANA. These are predominantly synchronous query integrations and therefore time-sensitive from a business-user perspective.' -GroupListItems @('IF_Commerce_TO_S4_MaterialStock', 'IF_Commerce_TO_S4_ListingsAndExclusions', 'IF_Commerce_TO_S4_GetInventoryReport') -GroupClosing 'The sections below contain information, descriptions of purpose and configuration parameters relevant to these processes.' -Title 'IF_Commerce_TO_S4_MaterialStock' -ArtifactRoot $materialStockFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: material stock information. Purpose: retrieve stock-related information from SAP S/4HANA for Commerce-driven product availability scenarios. Implementation: SAP Integration Suite exposes an HTTPS endpoint and forwards the request to the relevant SAP S/4HANA OData service using externally configured connectivity and credential parameters.'),
    (New-FlowEntry -GroupTitle 'Product and assortment queries' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_ListingsAndExclusions' -ArtifactRoot $listingsAndExclusionsFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: listing and exclusion data. Purpose: retrieve assortment-related information that determines whether products are listed or excluded for a given business context. Implementation: SAP Integration Suite exposes an HTTPS endpoint and mediates the request to the configured SAP S/4HANA OData service.'),
    (New-FlowEntry -GroupTitle 'Product and assortment queries' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_GetInventoryReport' -ArtifactRoot $getInventoryReportFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: inventory report data. Purpose: retrieve inventory reporting information from SAP S/4HANA for Commerce-facing use cases. Implementation: SAP Integration Suite exposes an inbound HTTPS endpoint and forwards the request to the configured SAP S/4HANA OData service while keeping technical connectivity settings externalized.'),

    (New-FlowEntry -GroupTitle 'Quote and order processing' -GroupIntro 'This section describes Commerce-originated integrations related to sales order and quotation handling in SAP S/4HANA. These flows provide simulation, retrieval, and execution capabilities used by Commerce-facing business processes.' -GroupListItems @('IF_Commerce_TO_S4_OrderSimulate', 'IF_Commerce_TO_S4_ManageSalesOrders', 'IF_Commerce_TO_S4_GetJobQuoteList', 'IF_Commerce_TO_S4_GetJobQuoteDetails') -GroupClosing 'The sections below contain information, descriptions of purpose and configuration parameters relevant to these processes.' -Title 'IF_Commerce_TO_S4_OrderSimulate' -ArtifactRoot $orderSimulateFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: sales order simulation requests. Purpose: simulate order scenarios in SAP S/4HANA before order creation or confirmation in Commerce. Implementation: SAP Integration Suite exposes an HTTPS endpoint and forwards the request to the SAP S/4HANA sales order simulation service using configured receiver parameters.'),
    (New-FlowEntry -GroupTitle 'Quote and order processing' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_ManageSalesOrders' -ArtifactRoot $manageSalesOrdersFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: sales orders. Purpose: create sales orders and retrieve existing order information from SAP S/4HANA. Implementation: SAP Integration Suite exposes an HTTPS endpoint and mediates the call to the configured SAP S/4HANA sales order OData service.'),
    (New-FlowEntry -GroupTitle 'Quote and order processing' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_GetJobQuoteList' -ArtifactRoot $getJobQuoteListFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: job quote list data. Purpose: retrieve quotation lists from SAP S/4HANA for Commerce-related business scenarios. Implementation: SAP Integration Suite exposes an HTTPS endpoint and forwards the request to the configured SAP S/4HANA quotation OData service.'),
    (New-FlowEntry -GroupTitle 'Quote and order processing' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_GetJobQuoteDetails' -ArtifactRoot $getJobQuoteDetailsFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: job quote detail data. Purpose: retrieve detailed quotation information from SAP S/4HANA for Commerce-related scenarios. Implementation: SAP Integration Suite exposes an HTTPS endpoint and forwards the request to the configured SAP S/4HANA quotation OData service.'),

    (New-FlowEntry -GroupTitle 'Invoice and billing retrieval' -GroupIntro 'This section describes Commerce-originated integrations that retrieve billing and invoice-related information from SAP S/4HANA.' -GroupListItems @('IF_Commerce_TO_S4_GetInvoiceList', 'IF_Commerce_TO_S4_GetInvoiceDetails', 'IF_Commerce_TO_S4_GetInvoicePDF') -GroupClosing 'The sections below contain information, descriptions of purpose and configuration parameters relevant to these processes.' -Title 'IF_Commerce_TO_S4_GetInvoiceList' -ArtifactRoot $invoiceFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: billing documents and invoice list data. Purpose: retrieve invoice information from SAP S/4HANA for Commerce-facing scenarios. Implementation: SAP Integration Suite exposes an inbound HTTPS endpoint, enriches and forwards the request to the SAP S/4HANA billing document OData service, and handles operational logging and exception processing in a centralized manner.'),
    (New-FlowEntry -GroupTitle 'Invoice and billing retrieval' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_GetInvoiceDetails' -ArtifactRoot $getInvoiceDetailsFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: invoice detail data. Purpose: retrieve detailed billing document information from SAP S/4HANA. Implementation: SAP Integration Suite exposes an HTTPS endpoint and forwards the request to the configured SAP S/4HANA billing document OData service.'),
    (New-FlowEntry -GroupTitle 'Invoice and billing retrieval' -GroupIntro '' -GroupListItems @() -GroupClosing '' -Title 'IF_Commerce_TO_S4_GetInvoicePDF' -ArtifactRoot $getInvoicePDFFlowRoot -EndpointLabel 'Endpoint (configured path)' -EndpointKey 'Sender address' -Description 'Direction: SAP Commerce Cloud to SAP S/4HANA. Object: invoice PDF content. Purpose: retrieve invoice PDF representations from SAP S/4HANA. Implementation: SAP Integration Suite exposes an HTTPS endpoint and mediates the request to the configured SAP S/4HANA billing PDF service.')
)

# Cover page
$cover1 = Find-Paragraph -TextContains 'Ostermann' -Occurrence 1
$cover2 = Find-Paragraph -TextContains 'SAP CX-Project' -Occurrence 1
$cover3 = Find-Paragraph -TextContains 'Documentation of SAP Integration Suite' -Occurrence 1
Set-ParagraphText -Paragraph $cover1 -Text 'TOTO'
Set-ParagraphText -Paragraph $cover2 -Text 'SAP Commerce Cloud & SAP S/4HANA Project'
Set-ParagraphText -Paragraph $cover3 -Text 'Documentation of SAP Integration Suite'

# Copyright
$copyrightTable = @($docXml.SelectNodes('//w:tbl', $ns))[0]
Set-CellText -Cell ($copyrightTable.SelectSingleNode('./w:tr[2]/w:tc[1]', $ns)) -Text 'The information contained herein is confidential and is for the sole use of TOTO and its stated professional advisors and agents. The contents may not be passed to any other parties without the express written permission of Needs to be filled in.'

# Document information section and tables
$vassHeading = Find-Paragraph -TextContains 'VASS Project Team Contact Information' -StyleId 'Heading2'
$customerHeading = Find-Paragraph -TextContains 'Ostermann Project Team Contact Information' -StyleId 'Heading2'
Set-ParagraphText -Paragraph $vassHeading -Text 'Implementation Partner Project Team Contact Information'
Set-ParagraphText -Paragraph $customerHeading -Text 'TOTO Project Team Contact Information'

$versionHeading = Find-Paragraph -TextContains 'Version Control' -StyleId 'Heading2'
$referenceHeading = Find-Paragraph -TextContains 'Reference Documents' -StyleId 'Heading2'
$acronymsHeading = Find-Paragraph -TextContains 'Acronyms' -StyleId 'Heading2'
$authHeading = Find-Paragraph -TextContains 'Authentication information' -StyleId 'Heading2'

$versionTable = Find-NextTableAfter -Node $versionHeading
$implTeamTable = Find-NextTableAfter -Node $vassHeading
$customerTeamTable = Find-NextTableAfter -Node $customerHeading
$referenceTable = Find-NextTableAfter -Node $referenceHeading
$acronymTable = Find-NextTableAfter -Node $acronymsHeading
$authTable = Find-NextTableAfter -Node $authHeading

$versionRows = @($versionTable.SelectNodes('./w:tr', $ns))
$versionHeaderCells = Ensure-RowCellCount -Row $versionRows[0] -DesiredCount 4
Set-CellText -Cell $versionHeaderCells[0] -Text 'Version'
Set-CellText -Cell $versionHeaderCells[1] -Text 'Date'
Set-CellText -Cell $versionHeaderCells[2] -Text 'Description'
Set-CellText -Cell $versionHeaderCells[3] -Text 'Author(s)'

$versionDataTemplate = $versionRows[1].CloneNode($true)
for ($i = $versionRows.Count - 1; $i -ge 1; $i--) {
    [void]$versionTable.RemoveChild($versionRows[$i])
}

$versionTableRows = @(
    @('0.2', (Get-Date -Format 'yyyy-MM-dd'), 'Updated landscape documentation structure and added Commerce and SAP S/4HANA integration process entries', 'Needs to be filled in'),
    @('', '', '', ''),
    @('', '', '', '')
)

foreach ($rowData in $versionTableRows) {
    $row = $versionDataTemplate.CloneNode($true)
    $cells = Ensure-RowCellCount -Row $row -DesiredCount 4
    for ($i = 0; $i -lt 4; $i++) {
        Set-CellText -Cell $cells[$i] -Text ([string]$rowData[$i])
    }
    [void]$versionTable.AppendChild($row)
}

Set-TableData -Table $implTeamTable -Headers @('Role', 'Name', 'Email', 'Phone') -Rows @(
    @('Project Manager', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in'),
    @('Integration Lead', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in'),
    @('Operations Contact', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in')
)

Set-TableData -Table $customerTeamTable -Headers @('Role', 'Name', 'Email', 'Phone') -Rows @(
    @('Business Owner', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in'),
    @('IT Contact', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in'),
    @('Support Contact', 'Needs to be filled in', 'Needs to be filled in', 'Needs to be filled in')
)

Set-TableData -Table $referenceTable -Headers @('Document name', 'Description') -Rows @(
    @('', ''),
    @('', ''),
    @('', '')
)

Set-TableData -Table $acronymTable -Headers @('Abbreviation', 'Description') -Rows @(
    @('API', 'Application Programming Interface'),
    @('B2B', 'Business-to-Business'),
    @('CI', 'Cloud Integration'),
    @('IDoc', 'Intermediate Document'),
    @('iFlow', 'Integration Flow'),
    @('OData', 'Open Data Protocol'),
    @('S/4HANA', 'SAP S/4HANA'),
    @('SOAP', 'Simple Object Access Protocol')
)

# Document Description section
Remove-NodesBetween -StartNode $documentDescriptionHeading -EndNode $designHeading
$docDescriptionParagraphs = @(
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'This document describes the SAP Integration Suite landscape for TOTO that connects SAP Commerce Cloud with SAP S/4HANA (on-premise). It is intended to serve as project-level technical documentation for the integration content that supports this landscape.'),
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'The broader enterprise integration landscape, both in general and in this project specifically, also includes systems such as SAP Sales Cloud, SAP Service Cloud, SAP Field Service Management, and other connected applications. This document is intentionally limited to the integration content that supports the SAP Commerce Cloud and SAP S/4HANA scope.'),
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'The current version documents a representative set of integration processes across both directions, including synchronous business queries, asynchronous master data replication flows, trigger flows, and shared utility processes. The same structure can be extended as additional integration flows are introduced.')
)
Add-NodesBefore -ReferenceNode $designHeading -Nodes $docDescriptionParagraphs

# Design / General approach
$generalApproachHeading = Find-Paragraph -TextContains 'General approach' -StyleId 'Heading2'
Remove-NodesBetween -StartNode $generalApproachHeading -EndNode $authHeading
$designParagraphs = @(
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'The integration landscape is bi-directional. It includes both process calls from SAP Commerce Cloud to SAP S/4HANA and replication or retrieval processes from SAP S/4HANA to SAP Commerce Cloud. SAP Integration Suite provides the central mediation, monitoring, and configuration layer and manages the controlled connectivity between the cloud and on-premise environments.'),
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'Where SAP standard integration content is available, it is reused as the implementation baseline. If project-specific requirements need to be addressed, the standard content is extended through clearly separated exit flows, trigger flows, or other dedicated customization components. When no suitable SAP standard content is available, the required process is implemented as custom integration content while following the same architectural and operational principles.'),
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'Many SAP Commerce Cloud initiated integrations are time-sensitive query processes because the user is waiting for information to be returned to the storefront or a related business application. To support this requirement, adapter settings such as endpoints and credentials are externalized where applicable, shared technical capabilities such as token handling and datastore access are isolated in reusable utility flows, and common assets such as script collections and value mappings are reused whenever appropriate.')
)
Add-NodesBefore -ReferenceNode $authHeading -Nodes $designParagraphs

$authGroupMap = [ordered]@{}
foreach ($entry in $flowEntries) {
    $credentialRows = @($entry.CredentialRows)
    if ($credentialRows.Count -eq 0) {
        continue
    }

    foreach ($credentialRow in $credentialRows) {
        $groupDefinition = Get-AuthenticationGroupDefinition -Direction $entry.Direction -CredentialKey $credentialRow.Key -CredentialValue $credentialRow.Value
        if ($null -eq $groupDefinition) {
            continue
        }

        if (-not $authGroupMap.Contains($groupDefinition.Key)) {
            $authGroupMap[$groupDefinition.Key] = [pscustomobject]@{
                Component = $groupDefinition.Component
                Direction = $groupDefinition.Direction
                Aliases = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
                FlowTitles = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
            }
        }

        $group = $authGroupMap[$groupDefinition.Key]
        [void]$group.FlowTitles.Add($entry.Title)
        [void]$group.Aliases.Add($credentialRow.Value)
    }
}

$authRows = New-Object System.Collections.ArrayList
[void]$authRows.Add(@('SAP Commerce Cloud', 'Inbound to SAP Integration Suite', 'Needs to be filled in', 'Inbound exposure and authentication details need to be filled in according to the productive security concept.'))

foreach ($groupKey in @('S4', 'Commerce', 'Internal')) {
    if (-not $authGroupMap.Contains($groupKey)) {
        continue
    }

    $group = $authGroupMap[$groupKey]
    $aliases = @($group.Aliases | Sort-Object)
    $flowTitles = @($group.FlowTitles | Sort-Object)
    $authText = 'Credential aliases: ' + ($aliases -join '; ')
    $remarkText = 'Used by: ' + ($flowTitles -join '; ')
    [void]$authRows.Add(@($group.Component, $group.Direction, $authText, $remarkText))
}

[void]$authRows.Add(@('Cloud Connector / network path', 'SAP Integration Suite to on-premise', 'Needs to be filled in', 'Location IDs and related connectivity details need to be maintained per landscape.'))

Set-TableData -Table $authTable -Headers @('Component', 'Direction', 'Authentication / Connectivity', 'Remark') -Rows @($authRows.ToArray())

# Implementation section
Remove-NodesBetween -StartNode $implementationHeading -EndNode $valueMappingsHeading

$implNodes = @()
$currentGroup = ''
$figureIndex = 1
$tableIndex = 7
foreach ($entry in $flowEntries) {
    if ($entry.GroupTitle -ne $currentGroup) {
        $currentGroup = $entry.GroupTitle
        $implNodes += Clone-ParagraphWithText -TemplateParagraph $heading2Template -Text $entry.GroupTitle
        $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text $entry.GroupIntro
        foreach ($item in $entry.GroupListItems) {
            $implNodes += Clone-ParagraphWithText -TemplateParagraph $listParagraphTemplate -Text $item
        }
        $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text $entry.GroupClosing
    }

    $implNodes += Clone-ParagraphWithText -TemplateParagraph $heading3Template -Text $entry.Title
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ''
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ('Integration flow name: ' + $entry.Title)
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ('Version: ' + $entry.Version)
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ($entry.EndpointLabel + ': ' + $entry.EndpointValue)
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'Screenshot:'
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ''
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $captionTemplate -Text ('Figure ' + $figureIndex + ': Screenshot of ' + $entry.Title)
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ''
    $implNodes += Clone-DescriptionParagraph -TemplateParagraph $bodyTemplateParagraph -Direction $entry.Direction -Object $entry.Object -Purpose $entry.Purpose -Implementation $entry.Implementation
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'External configuration parameters:'

    $paramTableClone = $parameterTableTemplate.CloneNode($true)
    Set-TableData -Table $paramTableClone -Headers @('Parameter name', 'Value') -Rows $entry.ExternalizedRows
    $implNodes += $paramTableClone
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $captionTemplate -Text ('Table ' + $tableIndex + ': Configuration parameters for ' + $entry.Title)
    $implNodes += Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text ''

    $figureIndex++
    $tableIndex++
}

Add-NodesBefore -ReferenceNode $valueMappingsHeading -Nodes $implNodes

# Value mappings section
$sectPr = $body.SelectSingleNode('./w:sectPr', $ns)
Remove-NodesBetween -StartNode $valueMappingsHeading -EndNode $sectPr
$valueMappingParagraphs = @(
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'This section contains value mappings that are deployed on the SAP CI tenant and contain entries that are referenced from the main processes (integration flows). Reusable value mappings should be documented here once they are introduced for the SAP Commerce Cloud and SAP S/4HANA integration landscape.'),
    (Clone-ParagraphWithText -TemplateParagraph $heading3Template -Text 'Shared value mappings for Commerce and SAP S/4HANA'),
    (Clone-ParagraphWithText -TemplateParagraph $bodyTemplateParagraph -Text 'No dedicated value mapping artifacts were provided as part of the packaged integration flows documented in this version. If reusable value mappings are introduced or documented separately, this section should be updated with their names, purpose, and the processes that reference them.')
)
Add-NodesBefore -ReferenceNode $sectPr -Nodes $valueMappingParagraphs

# Captions kept in same style, but content adjusted where needed
$captionParagraphs = @($docXml.SelectNodes('//w:p[w:pPr/w:pStyle[@w:val="Caption"]]', $ns))
foreach ($caption in $captionParagraphs) {
    $text = (Get-ParagraphText -Paragraph $caption).Trim()
    switch -Wildcard ($text) {
        'Table 2:*' { Set-ParagraphText -Paragraph $caption -Text 'Table 2: Implementation Partner Project Team Contact Information' }
        'Table 3:*' { Set-ParagraphText -Paragraph $caption -Text 'Table 3: TOTO Project Team Contact Information' }
    }
}

# Core properties cleanup
$corePath = Join-Path $tempDir 'docProps\core.xml'
[xml]$coreXml = Get-Content -Raw -Path $corePath
$coreXml.coreProperties.creator = 'Needs to be filled in'
$coreXml.coreProperties.lastModifiedBy = 'Needs to be filled in'
$coreXml.coreProperties.title = 'TOTO SAP Commerce Cloud and SAP S/4HANA Integration Suite Documentation'
$coreXml.coreProperties.subject = 'SAP Commerce Cloud and SAP S/4HANA integration documentation'
$coreXml.coreProperties.description = 'Project-level Cloud Integration documentation for TOTO'
$coreXml.Save($corePath)

$docXml.Save((Join-Path $tempDir 'word\document.xml'))

$finalOutputDoc = $outputDoc
$finalOutputZip = $outputZip

if (Test-Path $finalOutputDoc) {
    try {
        Remove-Item -Force -Path $finalOutputDoc -ErrorAction Stop
    }
    catch {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($outputDoc)
        $extension = [System.IO.Path]::GetExtension($outputDoc)
        $finalOutputDoc = Join-Path $outputDir ($baseName + '_' + $timestamp + $extension)
        $finalOutputZip = Join-Path $outputDir ($baseName + '_' + $timestamp + '.zip')
    }
}

if (Test-Path $finalOutputZip) { Remove-Item -Force $finalOutputZip }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($finalOutputZip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -Path $tempDir -Recurse -File) {
        $relative = $file.FullName.Substring($tempDir.Length).TrimStart('\').Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
}
finally {
    $archive.Dispose()
}

Move-Item -Path $finalOutputZip -Destination $finalOutputDoc

# Open and save once in Word so fields/layout are normalized in a real .docx editor.
$word = $null
$doc = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $doc = $word.Documents.Open($finalOutputDoc)
    $doc.Fields.Update() | Out-Null
    foreach ($toc in @($doc.TablesOfContents)) { $toc.Update() | Out-Null }
    foreach ($tof in @($doc.TablesOfFigures)) { $tof.Update() | Out-Null }
    $doc.Save()
}
finally {
    if ($doc -ne $null) { $doc.Close() }
    if ($word -ne $null) { $word.Quit() }
    if ($doc -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null }
    if ($word -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null }
}

Write-Output "Created: $finalOutputDoc"
