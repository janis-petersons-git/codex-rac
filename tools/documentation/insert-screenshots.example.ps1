$ErrorActionPreference = 'Stop'

$root = 'C:\Users\janis.petersons\Desktop\RS'
$docsDir = Join-Path $root 'generated_docs'
$manifestPath = Join-Path $root '_work\playwright_ci\artifacts\iflow_screenshots_canvaszoom_cropped\manifest.json'

$baseDoc = Join-Path $docsDir 'TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation_20260414_220915.docx'
if (-not (Test-Path $baseDoc)) {
    throw "Base documentation file not found: $baseDoc"
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputDoc = Join-Path $docsDir ("TOTO_SAP_CommerceCloud_S4HANA_Integration_Suite_Documentation_{0}.docx" -f $timestamp)
Copy-Item -Force $baseDoc $outputDoc

$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json

$word = $null
$doc = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.ScreenUpdating = $false

    $doc = $word.Documents.Open($outputDoc)
    $maxWidth = $doc.PageSetup.PageWidth - $doc.PageSetup.LeftMargin - $doc.PageSetup.RightMargin - 12

    foreach ($entry in $manifest) {
        $title = [string]$entry.title
        $imagePath = [string]$entry.screenshotPath
        if (-not (Test-Path $imagePath)) {
            continue
        }

        $captionText = "Screenshot of $title"
        $captionRange = $doc.Content
        $captionFind = $captionRange.Find
        $captionFind.ClearFormatting()
        $captionFind.Text = $captionText
        $captionFind.Forward = $true
        $captionFind.Wrap = 0

        if (-not $captionFind.Execute()) {
            Write-Warning "Could not find caption for $title"
            continue
        }

        $targetParagraph = $captionRange.Paragraphs.Item(1).Previous()
        if ($null -eq $targetParagraph) {
            Write-Warning "Could not find screenshot placeholder before caption for $title"
            continue
        }

        $targetRange = $targetParagraph.Range
        $targetRange.Text = ''

        $shape = $doc.InlineShapes.AddPicture($imagePath, $false, $true, $targetRange)
        $shape.LockAspectRatio = -1
        if ($shape.Width -gt $maxWidth) {
            $shape.Width = $maxWidth
        }
        $shape.Range.ParagraphFormat.Alignment = 1
    }

    $doc.Save()
    $doc.Close()
    $word.Quit()

    Write-Output "Created: $outputDoc"
}
finally {
    if ($doc -ne $null) {
        try { $doc.Close([ref]0) } catch {}
    }
    if ($word -ne $null) {
        try { $word.Quit() } catch {}
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
