param(
    [string]$SourceDoc = 'C:\Users\janis.petersons\Desktop\RS\generated_docs\TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation_20260415_164330.docx',
    [string]$OutputDir = 'C:\Users\janis.petersons\Desktop\RS\generated_docs'
)

$ErrorActionPreference = 'Stop'

function Read-JavaProperties {
    param([string]$Path)

    $result = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path) {
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

    [xml]$xml = Get-Content -Raw -LiteralPath $Path
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

function Get-ConfiguredExternalizedRows {
    param([string]$ArtifactRoot)

    $propsPath = Join-Path $ArtifactRoot 'src\main\resources\parameters.prop'
    $propDefPath = Join-Path $ArtifactRoot 'src\main\resources\parameters.propdef'
    if (-not (Test-Path $propsPath) -or -not (Test-Path $propDefPath)) {
        return @()
    }

    $props = Read-JavaProperties -Path $propsPath
    $keys = Get-ExternalizedParameterKeys -Path $propDefPath
    $rows = New-Object System.Collections.ArrayList
    foreach ($key in $keys) {
        if ($props.Contains($key)) {
            [void]$rows.Add([pscustomobject]@{
                Key = [string]$key
                Value = [string]$props[$key]
            })
        }
    }
    return ,($rows.ToArray())
}

function Get-NodeText {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlNode]$Node,
        [Parameter(Mandatory = $true)][System.Xml.XmlNamespaceManager]$Ns
    )

    return (($Node.SelectNodes('.//w:t', $Ns) | ForEach-Object { $_.InnerText }) -join '')
}

function Set-CellPlainText {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement]$Cell,
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory = $true)][System.Xml.XmlNamespaceManager]$Ns,
        [Parameter(Mandatory = $true)][string]$NamespaceUri
    )

    $paragraphs = @($Cell.SelectNodes('./w:p', $Ns))
    if ($paragraphs.Count -eq 0) {
        $paragraph = $Document.CreateElement('w', 'p', $NamespaceUri)
        [void]$Cell.AppendChild($paragraph)
        $paragraphs = @($paragraph)
    }

    $firstParagraph = $paragraphs[0]
    for ($i = $paragraphs.Count - 1; $i -ge 1; $i--) {
        [void]$Cell.RemoveChild($paragraphs[$i])
    }

    $pPr = $firstParagraph.SelectSingleNode('./w:pPr', $Ns)
    $runTemplate = $firstParagraph.SelectSingleNode('./w:r', $Ns)
    $rPrClone = $null
    if ($runTemplate -ne $null) {
        $runTemplateRPr = $runTemplate.SelectSingleNode('./w:rPr', $Ns)
        if ($runTemplateRPr -ne $null) {
            $rPrClone = $runTemplateRPr.CloneNode($true)
        }
    }

    foreach ($child in @($firstParagraph.ChildNodes)) {
        if ($pPr -ne $null -and $child -is [System.Xml.XmlElement] -and $child.LocalName -eq 'pPr') {
            continue
        }
        [void]$firstParagraph.RemoveChild($child)
    }

    $run = $Document.CreateElement('w', 'r', $NamespaceUri)
    if ($rPrClone -ne $null) {
        [void]$run.AppendChild($rPrClone)
    }
    $textNode = $Document.CreateElement('w', 't', $NamespaceUri)
    if ($Text -match '^\s' -or $Text -match '\s$') {
        $spaceAttr = $Document.CreateAttribute('xml', 'space', 'http://www.w3.org/XML/1998/namespace')
        $spaceAttr.Value = 'preserve'
        [void]$textNode.Attributes.Append($spaceAttr)
    }
    $textNode.InnerText = $Text
    [void]$run.AppendChild($textNode)
    [void]$firstParagraph.AppendChild($run)
}

$root = 'C:\Users\janis.petersons\Desktop\RS'
$flowRoots = [ordered]@{
    'Route Idocs From S4HANA To SAP Commerce Cloud' = Join-Path $root '_work\doc_flows\RouteIdocs'
    'Replicate Material From S4HANA To SAP Commerce Cloud' = Join-Path $root '_work\doc_flows\ReplicateMaterial'
    'Process Customized Material Pre Post Exits for S4HANA' = Join-Path $root '_work\doc_flows\MaterialExit'
    'Replicate B2B Customer From S4HANA To SAP Commerce Cloud_Modified' = Join-Path $root '_work\doc_flows\ReplicateB2BCustomer'
    'Access DataStore for S4HANA' = Join-Path $root '_work\doc_flows_more\Access DataStore for S4HANA _1_'
    'IF_CI_TO_S4_FetchToken' = Join-Path $root '_work\doc_flows_more\IF_CI_TO_S4_FetchToken'
    'IF_Commerce_TO_S4_GetInventoryReport' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInventoryReport'
    'IF_Commerce_TO_S4_GetInvoiceDetails' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoiceDetails'
    'IF_Commerce_TO_S4_GetInvoiceList' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoiceList'
    'IF_Commerce_TO_S4_GetInvoicePDF' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetInvoicePDF'
    'IF_Commerce_TO_S4_GetJobQuoteDetails' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetJobQuoteDetails'
    'IF_Commerce_TO_S4_GetJobQuoteList' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_GetJobQuoteList'
    'IF_Commerce_TO_S4_ListingsAndExclusions' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_ListingsAndExclusions'
    'IF_Commerce_TO_S4_ManageSalesOrders' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_ManageSalesOrders'
    'IF_Commerce_TO_S4_MaterialStock' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_MaterialStock'
    'IF_Commerce_TO_S4_OrderSimulate' = Join-Path $root '_work\doc_flows_more\IF_Commerce_TO_S4_OrderSimulate'
    'IF_S4_TO_Commerce_CommunicationPreferences' = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_CommunicationPreferences'
    'IF_S4_TO_Commerce_SalesKits' = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits'
    'IF_S4_TO_Commerce_SalesKits_ManualTrigger' = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits_ManualTrigger'
    'IF_S4_TO_Commerce_SalesKits_ScheduledTrigger' = Join-Path $root '_work\doc_flows_more\IF_S4_TO_Commerce_SalesKits_ScheduledTrigger'
}

$rowsByTitle = @{}
foreach ($title in $flowRoots.Keys) {
    $rowsByTitle[$title] = Get-ConfiguredExternalizedRows -ArtifactRoot $flowRoots[$title]
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$targetDoc = Join-Path $OutputDir "TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation_$timestamp.docx"

$tmpRoot = Join-Path $env:TEMP ('docx_param_patch_' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $env:TEMP ('docx_param_patch_' + [guid]::NewGuid().ToString('N') + '.zip')
New-Item -ItemType Directory -Path $tmpRoot | Out-Null
Copy-Item -LiteralPath $SourceDoc -Destination $zipPath -Force
Expand-Archive -LiteralPath $zipPath -DestinationPath $tmpRoot -Force

$documentXmlPath = Join-Path $tmpRoot 'word\document.xml'
$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true
$xml.Load($documentXmlPath)
$nsUri = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('w', $nsUri)

$captionParagraphs = @($xml.SelectNodes('//w:p[w:pPr/w:pStyle[@w:val="Caption"]]', $ns))
$updated = 0
foreach ($caption in $captionParagraphs) {
    $captionText = Get-NodeText -Node $caption -Ns $ns
    $match = [regex]::Match($captionText, '^Table\s+\d+:\s+Configuration parameters for\s+(?<Title>.+)$')
    if (-not $match.Success) {
        continue
    }

    $title = $match.Groups['Title'].Value.Trim()
    if (-not $rowsByTitle.ContainsKey($title)) {
        continue
    }

    $table = $caption.PreviousSibling
    while ($table -ne $null -and $table.LocalName -ne 'tbl') {
        $table = $table.PreviousSibling
    }
    if ($table -eq $null) {
        continue
    }

    $rows = $rowsByTitle[$title]
    $tableRows = @($table.SelectNodes('./w:tr', $ns))
    if ($tableRows.Count -lt 2) {
        continue
    }

    $templateRow = $tableRows[1].CloneNode($true)

    for ($i = $tableRows.Count - 1; $i -ge 1; $i--) {
        [void]$table.RemoveChild($tableRows[$i])
    }

    foreach ($rowData in $rows) {
        $newRow = $templateRow.CloneNode($true)
        $cells = @($newRow.SelectNodes('./w:tc', $ns))
        if ($cells.Count -lt 2) {
            continue
        }
        Set-CellPlainText -Cell $cells[0] -Text ([string]$rowData.Key) -Document $xml -Ns $ns -NamespaceUri $nsUri
        Set-CellPlainText -Cell $cells[1] -Text ([string]$rowData.Value) -Document $xml -Ns $ns -NamespaceUri $nsUri
        [void]$table.AppendChild($newRow)
    }

    Write-Host "Updated: $title ($($rows.Count) rows)"
    $updated++
}

$xml.Save($documentXmlPath)

$outZip = Join-Path $env:TEMP ('docx_param_patch_out_' + [guid]::NewGuid().ToString('N') + '.zip')
Compress-Archive -Path (Join-Path $tmpRoot '*') -DestinationPath $outZip -Force
Copy-Item -LiteralPath $outZip -Destination $targetDoc -Force

Remove-Item -LiteralPath $tmpRoot -Recurse -Force
Remove-Item -LiteralPath $zipPath -Force
Remove-Item -LiteralPath $outZip -Force

Write-Host "Created: $targetDoc"
Write-Host "Updated parameter tables: $updated"
